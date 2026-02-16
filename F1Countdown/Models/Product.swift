//
//  Product.swift
//  F1Countdown
//
//  StoreKit product model for Pro subscription
//

import Foundation
import StoreKit

// MARK: - Product ID

/// Product identifiers for the app
enum ProductID: String, CaseIterable {
    case pro = "com.f1countdown.pro"
    
    /// Display name for the product
    var displayName: String {
        switch self {
        case .pro:
            return "F1 Countdown Pro"
        }
    }
    
    /// Description for the product
    var productDescription: String {
        switch self {
        case .pro:
            return "Unlock all premium features with a one-time purchase"
        }
    }
}

// MARK: - Pro Feature

/// Features available to Pro users
enum ProFeature: String, CaseIterable, Codable {
    case lockScreenWidget = "lock_screen_widget"
    case liveActivities = "live_activities"
    case wallpapers = "wallpapers"
    case noAds = "no_ads"
    
    var displayName: String {
        switch self {
        case .lockScreenWidget:
            return "Lock Screen Widget"
        case .liveActivities:
            return "Dynamic Island Live Score"
        case .wallpapers:
            return "All Track Wallpapers"
        case .noAds:
            return "Ad-Free Experience"
        }
    }
    
    var description: String {
        switch self {
        case .lockScreenWidget:
            return "Beautiful countdown widgets on your lock screen"
        case .liveActivities:
            return "Real-time race updates on Dynamic Island"
        case .wallpapers:
            return "High-quality wallpapers for all circuits"
        case .noAds:
            return "Enjoy the app without any advertisements"
        }
    }
    
    var iconName: String {
        switch self {
        case .lockScreenWidget:
            return "rectangle.topthird.inset.filled"
        case .liveActivities:
            return "waveform.path"
        case .wallpapers:
            return "photo.fill"
        case .noAds:
            return "checkmark.shield.fill"
        }
    }
}

// MARK: - Purchase Result

/// Result of a purchase attempt
enum PurchaseResult: Equatable {
    case success
    case userCancelled
    case pending
    case failed(Error?)
    
    static func == (lhs: PurchaseResult, rhs: PurchaseResult) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success):
            return true
        case (.userCancelled, .userCancelled):
            return true
        case (.pending, .pending):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// MARK: - Transaction State

/// State of a transaction
enum TransactionState: String {
    case purchased
    case failed
    case restored
    case pending
    case deferred
    
    var displayName: String {
        switch self {
        case .purchased:
            return "Purchased"
        case .failed:
            return "Failed"
        case .restored:
            return "Restored"
        case .pending:
            return "Pending"
        case .deferred:
            return "Awaiting Approval"
        }
    }
}

// MARK: - App Product

/// Represents a product available for purchase
struct AppProduct: Identifiable, Hashable {
    let id: String
    let productID: ProductID
    let displayName: String
    let description: String
    let price: Decimal
    let displayPrice: String
    let currencyCode: String?
    
    /// Create from StoreKit Product
    init?(from storeKitProduct: Product) {
        guard let productID = ProductID(rawValue: storeKitProduct.id) else {
            return nil
        }
        
        self.id = storeKitProduct.id
        self.productID = productID
        self.displayName = storeKitProduct.displayName
        self.description = storeKitProduct.description
        self.price = storeKitProduct.price
        self.displayPrice = storeKitProduct.displayPrice
        self.currencyCode = storeKitProduct.currencyCode
    }
    
    /// Create a placeholder for loading state
    static var placeholder: AppProduct {
        AppProduct(
            id: ProductID.pro.rawValue,
            productID: .pro,
            displayName: ProductID.pro.displayName,
            description: ProductID.pro.productDescription,
            price: 18,
            displayPrice: "¥18",
            currencyCode: "CNY"
        )
    }
}

// MARK: - Product Extension for AppProduct

extension AppProduct {
    /// All Pro features included with purchase
    var includedFeatures: [ProFeature] {
        ProFeature.allCases
    }
    
    /// Formatted price string
    var formattedPrice: String {
        displayPrice
    }
    
    /// Whether this is a one-time purchase (non-consumable)
    var isOneTimePurchase: Bool {
        true
    }
}

// MARK: - StoreKit Product Extension

extension Product {
    /// Convert to AppProduct
    var toAppProduct: AppProduct? {
        AppProduct(from: self)
    }
}
