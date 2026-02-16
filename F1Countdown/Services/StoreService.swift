//
//  StoreService.swift
//  F1Countdown
//
//  StoreKit 2 service for handling in-app purchases
//

import Foundation
import StoreKit
import Combine

// MARK: - Store Service Error

/// Errors that can occur during store operations
enum StoreError: Error, LocalizedError {
    case productNotFound
    case purchaseFailed(Error?)
    case verificationFailed
    case networkError
    case notAvailableInSimulator
    case unknown(Error?)
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed(let error):
            if let error = error {
                return "Purchase failed: \(error.localizedDescription)"
            }
            return "Purchase failed"
        case .verificationFailed:
            return "Purchase verification failed"
        case .networkError:
            return "Network connection error"
        case .notAvailableInSimulator:
            return "StoreKit is not available in the simulator"
        case .unknown(let error):
            if let error = error {
                return "Unknown error: \(error.localizedDescription)"
            }
            return "Unknown error"
        }
    }
}

// MARK: - Store Service Protocol

/// Protocol defining store service capabilities
protocol StoreServiceProtocol {
    /// Available products
    var products: [AppProduct] { get }
    
    /// Whether the user is a Pro user
    var isProUser: Bool { get }
    
    /// Loading state
    var isLoading: Bool { get }
    
    /// Current error
    var error: StoreError? { get }
    
    /// Load available products
    func loadProducts() async throws
    
    /// Purchase a product
    func purchase(product: AppProduct) async throws -> PurchaseResult
    
    /// Restore previous purchases
    func restorePurchases() async throws
    
    /// Check if a feature is unlocked
    func isFeatureUnlocked(_ feature: ProFeature) -> Bool
}

// MARK: - Store Service

/// Service responsible for managing in-app purchases with StoreKit 2
@MainActor
final class StoreService: ObservableObject, StoreServiceProtocol {
    
    // MARK: - Published Properties
    
    /// Available products loaded from App Store
    @Published private(set) var products: [AppProduct] = []
    
    /// Whether the user has unlocked Pro features
    @Published private(set) var isProUser: Bool = false
    
    /// Loading state
    @Published private(set) var isLoading: Bool = false
    
    /// Current error if any
    @Published private(set) var error: StoreError?
    
    /// Current transaction state
    @Published private(set) var transactionState: TransactionState?
    
    // MARK: - Private Properties
    
    /// Set of transaction listeners
    private var transactionListenerTask: Task<Void, Error>?
    
    /// User defaults key for Pro status
    private let proStatusKey = "com.f1countdown.isProUser"
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    
    /// Shared instance
    static let shared = StoreService()
    
    // MARK: - Initialization
    
    private init() {
        // Load cached Pro status
        loadCachedProStatus()
        
        // Start listening for transactions
        startTransactionListener()
        
        // Load products on init
        Task {
            try? await loadProducts()
            await checkPurchasedStatus()
        }
    }
    
    deinit {
        transactionListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Load available products from App Store
    func loadProducts() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        // Get product IDs
        let productIDs = ProductID.allCases.map { $0.rawValue }
        
        do {
            // Fetch products from StoreKit
            let storeProducts = try await Product.products(for: productIDs)
            
            // Convert to AppProduct
            products = storeProducts.compactMap { $0.toAppProduct }
            
            if products.isEmpty {
                #if targetEnvironment(simulator)
                // In simulator, use placeholder for testing
                products = [AppProduct.placeholder]
                #else
                throw StoreError.productNotFound
                #endif
            }
        } catch let error as StoreError {
            self.error = error
            throw error
        } catch {
            self.error = .networkError
            throw StoreError.networkError
        }
    }
    
    /// Purchase a product
    /// - Parameter product: The product to purchase
    /// - Returns: Purchase result
    func purchase(product: AppProduct) async throws -> PurchaseResult {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        // Find the StoreKit product
        guard let storeProduct = try await Product.products(for: [product.id]).first else {
            throw StoreError.productNotFound
        }
        
        do {
            // Begin purchase
            let result = try await storeProduct.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the transaction
                switch verification {
                case .verified(let transaction):
                    // Transaction verified
                    await processVerifiedTransaction(transaction)
                    transactionState = .purchased
                    return .success
                    
                case .unverified(_, _):
                    // Verification failed
                    error = .verificationFailed
                    transactionState = .failed
                    return .failed(StoreError.verificationFailed)
                }
                
            case .userCancelled:
                transactionState = .failed
                return .userCancelled
                
            case .pending:
                transactionState = .pending
                return .pending
                
            @unknown default:
                error = .unknown(nil)
                transactionState = .failed
                return .failed(nil)
            }
        } catch {
            self.error = .purchaseFailed(error)
            transactionState = .failed
            return .failed(error)
        }
    }
    
    /// Restore previous purchases
    func restorePurchases() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            // Check for any entitlements
            var restored = false
            
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.productID == ProductID.pro.rawValue {
                        await processVerifiedTransaction(transaction)
                        restored = true
                        transactionState = .restored
                    }
                    
                case .unverified(_, _):
                    continue
                }
            }
            
            if !restored {
                // Sync with App Store
                try await AppStore.sync()
                
                // Check again after sync
                for await result in Transaction.currentEntitlements {
                    switch result {
                    case .verified(let transaction):
                        if transaction.productID == ProductID.pro.rawValue {
                            await processVerifiedTransaction(transaction)
                            restored = true
                            transactionState = .restored
                        }
                        
                    case .unverified(_, _):
                        continue
                    }
                }
            }
            
            if !restored {
                transactionState = .failed
                throw StoreError.productNotFound
            }
        } catch {
            self.error = .purchaseFailed(error)
            throw error
        }
    }
    
    /// Check if a specific Pro feature is unlocked
    /// - Parameter feature: The feature to check
    /// - Returns: Whether the feature is unlocked
    func isFeatureUnlocked(_ feature: ProFeature) -> Bool {
        isProUser
    }
    
    // MARK: - Private Methods
    
    /// Start listening for transaction updates
    private func startTransactionListener() {
        transactionListenerTask = Task {
            for await result in Transaction.updates {
                await handleTransactionUpdate(result)
            }
        }
    }
    
    /// Handle transaction updates from StoreKit
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            await processVerifiedTransaction(transaction)
            
        case .unverified(_, _):
            error = .verificationFailed
            transactionState = .failed
        }
    }
    
    /// Process a verified transaction
    private func processVerifiedTransaction(_ transaction: Transaction) async {
        // Check if this is our Pro product
        guard transaction.productID == ProductID.pro.rawValue else { return }
        
        // Update Pro status
        isProUser = transaction.revocationDate == nil
        saveProStatus(isProUser)
        
        // Finish the transaction
        await transaction.finish()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .proStatusChanged, object: nil)
    }
    
    /// Check purchased status on app launch
    private func checkPurchasedStatus() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == ProductID.pro.rawValue && transaction.revocationDate == nil {
                    isProUser = true
                    saveProStatus(true)
                    return
                }
                
            case .unverified(_, _):
                continue
            }
        }
        
        // No valid entitlement found, use cached status
        loadCachedProStatus()
    }
    
    /// Save Pro status to UserDefaults
    private func saveProStatus(_ isPro: Bool) {
        UserDefaults.standard.set(isPro, forKey: proStatusKey)
    }
    
    /// Load cached Pro status from UserDefaults
    private func loadCachedProStatus() {
        isProUser = UserDefaults.standard.bool(forKey: proStatusKey)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when Pro status changes
    static let proStatusChanged = Notification.Name("com.f1countdown.proStatusChanged")
}

// MARK: - Preview Support

extension StoreService {
    /// Create a preview store service with mock data
    static var preview: StoreService {
        let service = StoreService()
        service.products = [AppProduct.placeholder]
        return service
    }
    
    /// Create a preview store service with Pro already unlocked
    static var previewPro: StoreService {
        let service = StoreService()
        service.products = [AppProduct.placeholder]
        service.isProUser = true
        return service
    }
}

// MARK: - StoreKit Configuration Helper

extension StoreService {
    /// Check if StoreKit testing is available
    static var isStoreKitTestingAvailable: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Get the StoreKit configuration file name
    static var storeKitConfigurationFileName: String {
        "Products"
    }
}
