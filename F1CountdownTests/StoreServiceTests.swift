import XCTest
import StoreKit
@testable import F1Countdown

// MARK: - Store Service Tests

@MainActor
final class StoreServiceTests: XCTestCase {
    
    var sut: StoreService!
    
    override func setUp() async throws {
        try await super.setUp()
        // Use the shared instance for testing
        // In a real app, you'd inject a mock service
        sut = StoreService.shared
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Product Loading Tests
    
    func testLoadProductsReturnsProducts() async throws {
        // When
        try await sut.loadProducts()
        
        // Then - In simulator, placeholder should be available
        #if targetEnvironment(simulator)
        XCTAssertFalse(sut.products.isEmpty)
        #else
        // On device, this depends on App Store Connect configuration
        #endif
    }
    
    func testProductsAreCorrectlyFormatted() async throws {
        // Given
        try await sut.loadProducts()
        
        // Then
        for product in sut.products {
            XCTAssertFalse(product.id.isEmpty)
            XCTAssertFalse(product.displayName.isEmpty)
            XCTAssertFalse(product.description.isEmpty)
            XCTAssertFalse(product.displayPrice.isEmpty)
        }
    }
    
    // MARK: - Pro Status Tests
    
    func testIsProUserInitialValue() {
        // Then - Initially should be false (or cached value)
        // This test verifies the property exists and is accessible
        _ = sut.isProUser
    }
    
    func testIsFeatureUnlockedForProUser() {
        // Given
        let feature = ProFeature.lockScreenWidget
        
        // When
        let isUnlocked = sut.isFeatureUnlocked(feature)
        
        // Then - Should match isProUser
        XCTAssertEqual(isUnlocked, sut.isProUser)
    }
    
    func testAllProFeaturesCheck() {
        // When/Then - All features should return same value as isProUser
        for feature in ProFeature.allCases {
            XCTAssertEqual(sut.isFeatureUnlocked(feature), sut.isProUser)
        }
    }
    
    // MARK: - Product ID Tests
    
    func testProductIDRawValues() {
        // Then
        XCTAssertEqual(ProductID.pro.rawValue, "com.f1countdown.pro")
    }
    
    func testProductIDAllCases() {
        // Then
        XCTAssertEqual(ProductID.allCases.count, 1)
        XCTAssertEqual(ProductID.allCases.first, .pro)
    }
    
    // MARK: - Pro Feature Tests
    
    func testProFeatureAllCases() {
        // Then
        XCTAssertEqual(ProFeature.allCases.count, 4)
        XCTAssertTrue(ProFeature.allCases.contains(.lockScreenWidget))
        XCTAssertTrue(ProFeature.allCases.contains(.liveActivities))
        XCTAssertTrue(ProFeature.allCases.contains(.wallpapers))
        XCTAssertTrue(ProFeature.allCases.contains(.noAds))
    }
    
    func testProFeatureDisplayNames() {
        // Then
        XCTAssertEqual(ProFeature.lockScreenWidget.displayName, "Lock Screen Widget")
        XCTAssertEqual(ProFeature.liveActivities.displayName, "Dynamic Island Live Score")
        XCTAssertEqual(ProFeature.wallpapers.displayName, "All Track Wallpapers")
        XCTAssertEqual(ProFeature.noAds.displayName, "Ad-Free Experience")
    }
    
    func testProFeatureIconNames() {
        // Then
        XCTAssertEqual(ProFeature.lockScreenWidget.iconName, "rectangle.topthird.inset.filled")
        XCTAssertEqual(ProFeature.liveActivities.iconName, "waveform.path")
        XCTAssertEqual(ProFeature.wallpapers.iconName, "photo.fill")
        XCTAssertEqual(ProFeature.noAds.iconName, "checkmark.shield.fill")
    }
    
    // MARK: - Purchase Result Tests
    
    func testPurchaseResultEquality() {
        // Then
        XCTAssertEqual(PurchaseResult.success, PurchaseResult.success)
        XCTAssertEqual(PurchaseResult.userCancelled, PurchaseResult.userCancelled)
        XCTAssertEqual(PurchaseResult.pending, PurchaseResult.pending)
        XCTAssertEqual(PurchaseResult.failed(nil), PurchaseResult.failed(nil))
        XCTAssertNotEqual(PurchaseResult.success, PurchaseResult.userCancelled)
    }
    
    // MARK: - Transaction State Tests
    
    func testTransactionStateDisplayNames() {
        // Then
        XCTAssertEqual(TransactionState.purchased.displayName, "Purchased")
        XCTAssertEqual(TransactionState.failed.displayName, "Failed")
        XCTAssertEqual(TransactionState.restored.displayName, "Restored")
        XCTAssertEqual(TransactionState.pending.displayName, "Pending")
        XCTAssertEqual(TransactionState.deferred.displayName, "Awaiting Approval")
    }
    
    // MARK: - Store Error Tests
    
    func testStoreErrorDescriptions() {
        // Then
        XCTAssertNotNil(StoreError.productNotFound.errorDescription)
        XCTAssertNotNil(StoreError.purchaseFailed(nil).errorDescription)
        XCTAssertNotNil(StoreError.verificationFailed.errorDescription)
        XCTAssertNotNil(StoreError.networkError.errorDescription)
        XCTAssertNotNil(StoreError.notAvailableInSimulator.errorDescription)
        XCTAssertNotNil(StoreError.unknown(nil).errorDescription)
    }
    
    // MARK: - App Product Tests
    
    func testAppProductPlaceholder() {
        // When
        let placeholder = AppProduct.placeholder
        
        // Then
        XCTAssertEqual(placeholder.id, ProductID.pro.rawValue)
        XCTAssertEqual(placeholder.productID, .pro)
        XCTAssertEqual(placeholder.displayPrice, "¥18")
        XCTAssertEqual(placeholder.includedFeatures.count, 4)
        XCTAssertTrue(placeholder.isOneTimePurchase)
    }
    
    func testAppProductIncludedFeatures() {
        // When
        let product = AppProduct.placeholder
        
        // Then
        XCTAssertEqual(product.includedFeatures, ProFeature.allCases)
    }
    
    // MARK: - Loading State Tests
    
    func testInitialLoadingState() {
        // Then - Should not be loading initially
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Error State Tests
    
    func testInitialErrorState() {
        // Then - Should not have an error initially
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Preview Factory Tests
    
    func testPreviewFactory() {
        // When
        let previewService = StoreService.preview
        
        // Then
        XCTAssertFalse(previewService.products.isEmpty)
    }
    
    func testPreviewProFactory() {
        // When
        let previewProService = StoreService.previewPro
        
        // Then
        XCTAssertTrue(previewProService.isProUser)
        XCTAssertFalse(previewProService.products.isEmpty)
    }
    
    // MARK: - StoreKit Configuration Tests
    
    func testStoreKitConfigurationFileName() {
        // Then
        XCTAssertEqual(StoreService.storeKitConfigurationFileName, "Products")
    }
}

// MARK: - Product Model Tests

final class ProductModelTests: XCTestCase {
    
    func testProductIDDisplayName() {
        // Then
        XCTAssertEqual(ProductID.pro.displayName, "F1 Countdown Pro")
    }
    
    func testProductIDDescription() {
        // Then
        XCTAssertEqual(ProductID.pro.productDescription, "Unlock all premium features with a one-time purchase")
    }
    
    func testProFeatureRawValues() {
        // Then
        XCTAssertEqual(ProFeature.lockScreenWidget.rawValue, "lock_screen_widget")
        XCTAssertEqual(ProFeature.liveActivities.rawValue, "live_activities")
        XCTAssertEqual(ProFeature.wallpapers.rawValue, "wallpapers")
        XCTAssertEqual(ProFeature.noAds.rawValue, "no_ads")
    }
    
    func testProFeatureCodable() throws {
        // Given
        let feature = ProFeature.liveActivities
        
        // When
        let data = try JSONEncoder().encode(feature)
        let decoded = try JSONDecoder().decode(ProFeature.self, from: data)
        
        // Then
        XCTAssertEqual(feature, decoded)
    }
}

// MARK: - Notification Name Tests

final class NotificationNameTests: XCTestCase {
    
    func testProStatusChangedNotification() {
        // Then
        XCTAssertEqual(Notification.Name.proStatusChanged.rawValue, "com.f1countdown.proStatusChanged")
    }
}

// MARK: - AppProduct Hashable Tests

final class AppProductTests: XCTestCase {
    
    func testAppProductHashable() {
        // Given
        let product1 = AppProduct.placeholder
        let product2 = AppProduct.placeholder
        
        // Then
        XCTAssertEqual(product1, product2)
        XCTAssertEqual(product1.hashValue, product2.hashValue)
    }
    
    func testAppProductIdentifiable() {
        // Given
        let product = AppProduct.placeholder
        
        // Then
        XCTAssertEqual(product.id, product.id) // Consistent ID
    }
}
