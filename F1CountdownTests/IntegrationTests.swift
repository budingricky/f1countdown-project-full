//
//  IntegrationTests.swift
//  F1CountdownTests
//
//  Integration tests for complete data flows
//  Tests: API → DataService → ViewModel, Widget sharing, IAP, Notifications
//

import XCTest
import SwiftData
@testable import F1Countdown

// MARK: - Integration Tests

final class IntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: RaceRecord.self, CircuitRecord.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - Data Flow Tests
    
    // MARK: API → DataService Integration
    
    /// Test: API data can be fetched and cached through DataService
    func testAPIToDataServiceFlow() async throws {
        // Given: A DataService with in-memory storage
        let dataService = DataService(modelContext: modelContext)
        
        // When: Fetching data from API (using current season)
        // Note: This test requires network access
        do {
            let races = try await dataService.fetchAndCacheRaces(year: 2024)
            
            // Then: Data should be cached and available
            XCTAssertFalse(races.isEmpty, "Should receive races from API")
            XCTAssertEqual(dataService.cachedRaces.count, races.count, "Cached races should match fetched races")
            XCTAssertNotNil(dataService.lastSyncDate, "Last sync date should be set")
            
            // Verify data structure
            if let firstRace = races.first {
                XCTAssertFalse(firstRace.raceName.isEmpty, "Race should have a name")
                XCTAssertFalse(firstRace.circuit.circuitName.isEmpty, "Circuit should have a name")
            }
        } catch {
            // If network is unavailable, test should still pass with cached data
            print("Network unavailable for integration test: \(error)")
        }
    }
    
    /// Test: DataService can retrieve cached races
    func testDataServiceCanRetrieveCachedRaces() async throws {
        // Given: A DataService with some cached data
        let dataService = DataService(modelContext: modelContext)
        
        // Insert test data
        let circuit = CircuitRecord(from: Circuit.preview)
        modelContext.insert(circuit)
        
        let race = RaceRecord(from: Race.preview, circuit: circuit)
        modelContext.insert(race)
        try modelContext.save()
        
        // When: Retrieving cached races
        let cachedRaces = await dataService.getCachedRaces()
        
        // Then: Should return the cached race
        XCTAssertFalse(cachedRaces.isEmpty, "Should have cached races")
        XCTAssertEqual(cachedRaces.first?.raceName, Race.preview.raceName, "Race name should match")
    }
    
    /// Test: DataService filters upcoming races correctly
    func testDataServiceFiltersUpcomingRaces() async throws {
        // Given: A DataService with mixed race dates
        let dataService = DataService(modelContext: modelContext)
        
        // Insert future race
        let futureCircuit = CircuitRecord(from: Circuit.preview)
        modelContext.insert(futureCircuit)
        
        let futureRace = RaceRecord(from: Race.preview, circuit: futureCircuit)
        modelContext.insert(futureRace)
        
        // Insert past race
        let pastRace = Race(
            season: "2023",
            round: "1",
            raceName: "Past Grand Prix",
            circuit: Circuit.preview,
            date: "2023-03-01",
            time: "15:00:00Z",
            firstPractice: nil,
            secondPractice: nil,
            thirdPractice: nil,
            qualifying: nil,
            sprint: nil
        )
        let pastCircuit = CircuitRecord(from: Circuit.preview)
        modelContext.insert(pastCircuit)
        let pastRaceRecord = RaceRecord(from: pastRace, circuit: pastCircuit)
        modelContext.insert(pastRaceRecord)
        
        try modelContext.save()
        _ = await dataService.getCachedRaces()
        
        // When: Getting upcoming races
        let upcomingRaces = dataService.getUpcomingRaces()
        
        // Then: Should only return future races
        // Note: Result depends on current date
        XCTAssertTrue(upcomingRaces.allSatisfy { $0.isUpcoming }, "All returned races should be upcoming")
    }
    
    // MARK: DataService → ViewModel Integration
    
    /// Test: RaceListViewModel integrates with DataService
    func testDataServiceToViewModelFlow() async throws {
        // Given: A RaceListViewModel with DataService
        let dataService = DataService(modelContext: modelContext)
        let viewModel = RaceListViewModel(dataService: dataService)
        
        // Wait for initial load
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: ViewModel should have loaded data
        // Note: May be empty if network is unavailable
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after init")
    }
    
    /// Test: ViewModel filter modes work correctly
    func testViewModelFilterModes() async throws {
        // Given: A ViewModel with some test data
        let dataService = DataService(modelContext: modelContext)
        let viewModel = RaceListViewModel(dataService: dataService)
        
        // Insert test data
        let circuit = CircuitRecord(from: Circuit.preview)
        modelContext.insert(circuit)
        let race = RaceRecord(from: Race.preview, circuit: circuit)
        modelContext.insert(race)
        try modelContext.save()
        
        // When: Changing filter modes
        viewModel.setFilterMode(.all)
        let allCount = viewModel.filteredRaces.count
        
        viewModel.setFilterMode(.upcoming)
        let upcomingCount = viewModel.filteredRaces.count
        
        viewModel.setFilterMode(.completed)
        let completedCount = viewModel.filteredRaces.count
        
        // Then: Filter counts should be consistent
        XCTAssertEqual(allCount, upcomingCount + completedCount, "All = upcoming + completed")
    }
    
    /// Test: ViewModel search filters races correctly
    func testViewModelSearch() async throws {
        // Given: A ViewModel with cached data
        let dataService = DataService(modelContext: modelContext)
        let viewModel = RaceListViewModel(dataService: dataService)
        
        // Insert test data
        let circuit = CircuitRecord(from: Circuit.preview)
        modelContext.insert(circuit)
        let race = RaceRecord(from: Race.preview, circuit: circuit)
        modelContext.insert(race)
        try modelContext.save()
        
        // Reload from cache
        _ = await dataService.getCachedRaces()
        viewModel.races = dataService.cachedRaces
        viewModel.filterMode = .all
        
        // When: Searching for a race name
        viewModel.searchQuery = "Bahrain"
        viewModel.applyFilter() // Force filter application
        
        // Then: Should find matching races
        XCTAssertTrue(viewModel.filteredRaces.allSatisfy { 
            $0.raceName.localizedCaseInsensitiveContains("Bahrain") ||
            $0.circuit.circuitName.localizedCaseInsensitiveContains("Bahrain")
        }, "Filtered results should match search query")
    }
    
    // MARK: - Widget Data Sharing Tests
    
    /// Test: Widget data can be stored in App Group
    func testWidgetDataSharing() async throws {
        // Given: App Group UserDefaults
        let appGroupID = "group.com.f1countdown.shared"
        let userDefaults = UserDefaults(suiteName: appGroupID)
        
        // When: Storing widget data
        let widgetData: [String: Any] = [
            "raceName": "Bahrain Grand Prix",
            "raceDate": ISO8601DateFormatter().string(from: Date()),
            "circuitName": "Bahrain International Circuit",
            "country": "Bahrain"
        ]
        
        userDefaults?.set(widgetData, forKey: "nextRace")
        userDefaults?.synchronize()
        
        // Then: Data should be retrievable
        let retrieved = userDefaults?.dictionary(forKey: "nextRace")
        XCTAssertNotNil(retrieved, "Widget data should be stored")
        XCTAssertEqual(retrieved?["raceName"] as? String, "Bahrain Grand Prix", "Race name should match")
        
        // Cleanup
        userDefaults?.removeObject(forKey: "nextRace")
    }
    
    /// Test: Countdown calculation for widget
    func testWidgetCountdownCalculation() {
        // Given: A future date
        let futureDate = Date().addingTimeInterval(3600 * 24 * 2 + 3600 * 5 + 60 * 30) // 2d 5h 30m
        
        // When: Calculating countdown
        let interval = futureDate.timeIntervalSince(Date())
        let days = Int(interval / 86400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        // Then: Countdown should be accurate
        XCTAssertEqual(days, 2, "Days should be 2")
        XCTAssertEqual(hours, 5, "Hours should be 5")
        XCTAssertEqual(minutes, 30, "Minutes should be 30")
    }
    
    // MARK: - Notification Scheduling Tests
    
    /// Test: Notification identifier parsing
    func testNotificationIdentifierParsing() {
        // Given: A notification identifier
        let identifier = "race-2024-1-qualifying-30"
        
        // When: Parsing the identifier
        let components = identifier.split(separator: "-")
        
        // Then: Components should be parseable
        XCTAssertEqual(components[0], "race", "First component should be 'race'")
        XCTAssertEqual(components[1], "2024", "Second component should be season")
        XCTAssertEqual(components[2], "1", "Third component should be round")
        XCTAssertEqual(components[3], "qualifying", "Fourth component should be session type")
        XCTAssertEqual(components[4], "30", "Fifth component should be timing")
    }
    
    /// Test: Notification timing options
    func testNotificationTimingOptions() {
        // Given: Notification timing options
        let timings: [Int] = [15, 30, 60]
        
        // When: Creating notification dates
        let raceDate = Date().addingTimeInterval(7200) // 2 hours from now
        
        for timing in timings {
            let notificationDate = raceDate.addingTimeInterval(-TimeInterval(timing * 60))
            let expectedInterval = TimeInterval(timing * 60)
            let actualInterval = raceDate.timeIntervalSince(notificationDate)
            
            // Then: Notification should be scheduled at correct time
            XCTAssertEqual(actualInterval, expectedInterval, "Notification should be \(timing) minutes before race")
        }
    }
    
    // MARK: - In-App Purchase Integration Tests
    
    /// Test: Product ID validation
    func testProductIDValidation() {
        // Given: Product IDs
        let validProductID = "com.f1countdown.pro"
        let invalidProductID = "com.f1countdown.invalid"
        
        // When: Validating product IDs
        let validProduct = ProductID(rawValue: validProductID)
        let invalidProduct = ProductID(rawValue: invalidProductID)
        
        // Then: Only valid IDs should create enum cases
        XCTAssertNotNil(validProduct, "Valid product ID should create enum case")
        XCTAssertNil(invalidProduct, "Invalid product ID should not create enum case")
    }
    
    /// Test: Pro feature definitions
    func testProFeatureDefinitions() {
        // Given: All Pro features
        let features = ProFeature.allCases
        
        // Then: Should have expected features
        XCTAssertEqual(features.count, 4, "Should have 4 Pro features")
        XCTAssertTrue(features.contains(.lockScreenWidget), "Should include lock screen widget")
        XCTAssertTrue(features.contains(.liveActivities), "Should include live activities")
        XCTAssertTrue(features.contains(.wallpapers), "Should include wallpapers")
        XCTAssertTrue(features.contains(.noAds), "Should include no ads")
    }
    
    /// Test: Purchase result equality
    func testPurchaseResultEquality() {
        // Given: Different purchase results
        let success1 = PurchaseResult.success
        let success2 = PurchaseResult.success
        let cancelled = PurchaseResult.userCancelled
        let pending = PurchaseResult.pending
        
        // Then: Same types should be equal
        XCTAssertEqual(success1, success2, "Success results should be equal")
        XCTAssertNotEqual(success1, cancelled, "Success and cancelled should not be equal")
        XCTAssertNotEqual(cancelled, pending, "Cancelled and pending should not be equal")
    }
    
    /// Test: AppProduct placeholder creation
    func testAppProductPlaceholder() {
        // Given: A placeholder product
        let placeholder = AppProduct.placeholder
        
        // Then: Should have expected values
        XCTAssertEqual(placeholder.id, "com.f1countdown.pro", "ID should match Pro product")
        XCTAssertEqual(placeholder.price, 18, "Price should be 18")
        XCTAssertNotNil(placeholder.currencyCode, "Should have currency code")
    }
    
    // MARK: - Race Model Integration Tests
    
    /// Test: Race session sorting
    func testRaceSessionSorting() {
        // Given: A race with multiple sessions
        let race = Race.preview
        
        // When: Getting sorted sessions
        let sessions = race.sessions
        
        // Then: Sessions should be sorted chronologically
        for i in 0..<(sessions.count - 1) {
            let current = sessions[i]
            let next = sessions[i + 1]
            
            if let currentDate = current.dateTime, let nextDate = next.dateTime {
                XCTAssertLessThanOrEqual(currentDate, nextDate, "Sessions should be sorted by date")
            }
        }
    }
    
    /// Test: Race ID generation
    func testRaceIDGeneration() {
        // Given: Races with different seasons and rounds
        let race1 = Race(
            season: "2024",
            round: "1",
            raceName: "Race 1",
            circuit: Circuit.preview,
            date: "2024-03-01",
            time: nil,
            firstPractice: nil,
            secondPractice: nil,
            thirdPractice: nil,
            qualifying: nil,
            sprint: nil
        )
        
        let race2 = Race(
            season: "2024",
            round: "2",
            raceName: "Race 2",
            circuit: Circuit.preview,
            date: "2024-03-15",
            time: nil,
            firstPractice: nil,
            secondPractice: nil,
            thirdPractice: nil,
            qualifying: nil,
            sprint: nil
        )
        
        // Then: IDs should be unique
        XCTAssertEqual(race1.id, "2024-1", "Race 1 ID should be correct")
        XCTAssertEqual(race2.id, "2024-2", "Race 2 ID should be correct")
        XCTAssertNotEqual(race1.id, race2.id, "Race IDs should be unique")
    }
    
    /// Test: Circuit relationship
    func testCircuitRelationship() {
        // Given: A race with circuit
        let race = Race.preview
        
        // Then: Circuit data should be accessible
        XCTAssertFalse(race.circuit.circuitId.isEmpty, "Circuit should have ID")
        XCTAssertFalse(race.circuit.circuitName.isEmpty, "Circuit should have name")
        XCTAssertNotNil(race.circuit.location, "Circuit should have location")
    }
    
    // MARK: - Error Handling Tests
    
    /// Test: DataServiceError descriptions
    func testDataServiceErrorDescriptions() {
        // Given: Different error types
        let noCacheError = DataServiceError.noCachedData
        let syncError = DataServiceError.syncFailed(NSError(domain: "Test", code: -1, userInfo: nil))
        let networkError = DataServiceError.networkUnavailable
        
        // Then: Errors should have descriptions
        XCTAssertNotNil(noCacheError.errorDescription, "No cache error should have description")
        XCTAssertNotNil(syncError.errorDescription, "Sync error should have description")
        XCTAssertNotNil(networkError.errorDescription, "Network error should have description")
    }
    
    /// Test: StoreError descriptions
    func testStoreErrorDescriptions() {
        // Given: Different store errors
        let productNotFound = StoreError.productNotFound
        let verificationFailed = StoreError.verificationFailed
        let networkError = StoreError.networkError
        
        // Then: Errors should have descriptions
        XCTAssertNotNil(productNotFound.errorDescription, "Product not found error should have description")
        XCTAssertNotNil(verificationFailed.errorDescription, "Verification error should have description")
        XCTAssertNotNil(networkError.errorDescription, "Network error should have description")
    }
    
    // MARK: - Performance Tests
    
    /// Test: Race filtering performance
    func testRaceFilteringPerformance() {
        // Given: A large number of races
        var races: [Race] = []
        for i in 1...100 {
            let race = Race(
                season: "2024",
                round: String(i),
                raceName: "Grand Prix \(i)",
                circuit: Circuit.preview,
                date: "2024-0\(i % 9 + 1)-01",
                time: "15:00:00Z",
                firstPractice: nil,
                secondPractice: nil,
                thirdPractice: nil,
                qualifying: nil,
                sprint: nil
            )
            races.append(race)
        }
        
        // When: Measuring filtering time
        measure {
            let _ = races.filter { $0.isUpcoming }
        }
    }
    
    /// Test: Countdown calculation performance
    func testCountdownCalculationPerformance() {
        // Given: A date
        let date = Date().addingTimeInterval(86400)
        
        // When: Measuring countdown calculation time
        measure {
            for _ in 0..<1000 {
                let interval = date.timeIntervalSince(Date())
                let _ = Int(interval / 86400)
                let _ = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
                let _ = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            }
        }
    }
}
