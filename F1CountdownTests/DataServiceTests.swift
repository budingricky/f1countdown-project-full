import XCTest
import SwiftData
@testable import F1Countdown

// MARK: - Data Service Tests

final class DataServiceTests: XCTestCase {
    
    var sut: DataService!
    var container: ModelContainer!
    var mockAPIClient: MockAPIClient!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory container for testing
        let schema = Schema([
            RaceRecord.self,
            CircuitRecord.self,
            SessionRecord.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: false
        )
        
        container = try ModelContainer(
            for: schema,
            configurations: configuration
        )
        
        mockAPIClient = MockAPIClient()
        sut = DataService(modelContext: container.mainContext, apiClient: mockAPIClient)
    }
    
    override func tearDown() async throws {
        sut = nil
        container = nil
        mockAPIClient = nil
        try await super.tearDown()
    }
    
    // MARK: - Fetch and Cache Tests
    
    func testFetchAndCacheRacesSuccess() async throws {
        // Given
        let expectedRaces = createTestRaces()
        mockAPIClient.racesToReturn = expectedRaces
        mockAPIClient.shouldFail = false
        
        // When
        let races = try await sut.fetchAndCacheRaces(year: 2024)
        
        // Then
        XCTAssertEqual(races.count, expectedRaces.count)
        XCTAssertEqual(sut.cachedRaces.count, expectedRaces.count)
        XCTAssertNotNil(sut.lastSyncDate)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testFetchAndCacheRacesNetworkError() async throws {
        // Given
        mockAPIClient.shouldFail = true
        mockAPIClient.errorToThrow = APIError.networkError(NSError(domain: "test", code: -1))
        
        // When/Then
        do {
            _ = try await sut.fetchAndCacheRaces(year: 2024)
            XCTFail("Should throw error")
        } catch let error as DataServiceError {
            if case .networkUnavailable = error {
                // Expected
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    func testFetchAndCacheRacesCurrentSeason() async throws {
        // Given
        let expectedRaces = createTestRaces()
        mockAPIClient.racesToReturn = expectedRaces
        
        // When
        let races = try await sut.fetchAndCacheRaces()
        
        // Then
        XCTAssertEqual(races.count, expectedRaces.count)
        XCTAssertTrue(mockAPIClient.fetchCurrentSeasonCalled)
    }
    
    // MARK: - Cache Retrieval Tests
    
    func testGetCachedRaces() async {
        // Given - populate cache
        let testRaces = createTestRaces()
        mockAPIClient.racesToReturn = testRaces
        _ = try? await sut.fetchAndCacheRaces(year: 2024)
        
        // When
        let cached = await sut.getCachedRaces(season: "2024")
        
        // Then
        XCTAssertEqual(cached.count, testRaces.count)
    }
    
    func testGetCachedRaceById() async {
        // Given - populate cache
        let testRaces = createTestRaces()
        mockAPIClient.racesToReturn = testRaces
        _ = try? await sut.fetchAndCacheRaces(year: 2024)
        
        // When
        let cached = await sut.getCachedRace(id: "2024-1")
        
        // Then
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.raceName, "Bahrain Grand Prix")
    }
    
    func testGetCachedRaceNotFound() async {
        // When
        let cached = await sut.getCachedRace(id: "nonexistent")
        
        // Then
        XCTAssertNil(cached)
    }
    
    // MARK: - Filter Tests
    
    func testGetUpcomingRaces() async throws {
        // Given - create races with future dates
        let futureDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 30))
        let pastDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 30))
        
        let futureRace = createRace(id: "2024-1", date: futureDate)
        let pastRace = createRace(id: "2024-2", date: pastDate)
        
        mockAPIClient.racesToReturn = [futureRace, pastRace]
        _ = try await sut.fetchAndCacheRaces(year: 2024)
        
        // When
        let upcoming = sut.getUpcomingRaces()
        
        // Then
        XCTAssertEqual(upcoming.count, 1)
        XCTAssertEqual(upcoming.first?.id, "2024-1")
    }
    
    func testGetCompletedRaces() async throws {
        // Given
        let futureDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 30))
        let pastDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 30))
        
        let futureRace = createRace(id: "2024-1", date: futureDate)
        let pastRace = createRace(id: "2024-2", date: pastDate)
        
        mockAPIClient.racesToReturn = [futureRace, pastRace]
        _ = try await sut.fetchAndCacheRaces(year: 2024)
        
        // When
        let completed = sut.getCompletedRaces()
        
        // Then
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed.first?.id, "2024-2")
    }
    
    func testGetNextRace() async throws {
        // Given
        let nearFuture = ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400))
        let farFuture = ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 7))
        
        let nearRace = createRace(id: "2024-near", date: nearFuture)
        let farRace = createRace(id: "2024-far", date: farFuture)
        
        mockAPIClient.racesToReturn = [farRace, nearRace] // Unsorted
        _ = try await sut.fetchAndCacheRaces(year: 2024)
        
        // When
        let next = sut.getNextRace()
        
        // Then
        XCTAssertEqual(next?.id, "2024-near")
    }
    
    // MARK: - Clear Cache Tests
    
    func testClearCache() async throws {
        // Given - populate cache
        let testRaces = createTestRaces()
        mockAPIClient.racesToReturn = testRaces
        _ = try await sut.fetchAndCacheRaces(year: 2024)
        XCTAssertFalse(sut.cachedRaces.isEmpty)
        
        // When
        try await sut.clearCache()
        
        // Then
        XCTAssertTrue(sut.cachedRaces.isEmpty)
        XCTAssertNil(sut.lastSyncDate)
    }
    
    // MARK: - Refresh Tests
    
    func testRefreshIfNeededWhenDue() async throws {
        // Given - no last sync
        XCTAssertNil(sut.lastSyncDate)
        
        let testRaces = createTestRaces()
        mockAPIClient.racesToReturn = testRaces
        
        // When
        try await sut.refreshIfNeeded()
        
        // Then
        XCTAssertNotNil(sut.lastSyncDate)
    }
    
    func testRefreshIfNeededWhenRecent() async throws {
        // Given - just synced
        let testRaces = createTestRaces()
        mockAPIClient.racesToReturn = testRaces
        _ = try await sut.fetchAndCacheRaces(year: 2024)
        
        let firstSyncDate = sut.lastSyncDate
        
        // When - try to refresh immediately
        try await sut.refreshIfNeeded()
        
        // Then - should not have refreshed (same date)
        XCTAssertEqual(sut.lastSyncDate, firstSyncDate)
        XCTAssertEqual(mockAPIClient.fetchCallCount, 1) // Only the initial call
    }
    
    // MARK: - Helper Methods
    
    private func createTestRaces() -> [Race] {
        [
            createRace(id: "2024-1", raceName: "Bahrain Grand Prix"),
            createRace(id: "2024-2", raceName: "Saudi Arabian Grand Prix"),
            createRace(id: "2024-3", raceName: "Australian Grand Prix")
        ]
    }
    
    private func createRace(id: String, raceName: String = "Test Grand Prix", date: String = "2024-03-02") -> Race {
        Race(
            season: "2024",
            round: String(id.split(separator: "-").last ?? "1"),
            raceName: raceName,
            circuit: Circuit(
                circuitId: "test-\(id)",
                circuitName: "Test Circuit",
                location: CircuitLocation(locality: "Test City", country: "Test Country")
            ),
            date: date,
            time: "15:00:00Z",
            firstPractice: SessionData(date: date, time: "11:30:00Z"),
            secondPractice: SessionData(date: date, time: "15:00:00Z"),
            thirdPractice: SessionData(date: date, time: "12:30:00Z"),
            qualifying: SessionData(date: date, time: "16:00:00Z"),
            sprint: nil
        )
    }
}

// MARK: - Mock API Client

final class MockAPIClient: APIClient {
    var racesToReturn: [Race] = []
    var shouldFail = false
    var errorToThrow: Error?
    var fetchCallCount = 0
    var fetchCurrentSeasonCalled = false
    
    override init(session: URLSession = .shared) {
        super.init(session: session)
    }
    
    override func fetchSeason(year: Int) async throws -> [Race] {
        fetchCallCount += 1
        if shouldFail {
            if let error = errorToThrow {
                throw error
            }
            throw APIError.networkError(NSError(domain: "test", code: -1))
        }
        return racesToReturn
    }
    
    override func fetchCurrentSeason() async throws -> [Race] {
        fetchCurrentSeasonCalled = true
        fetchCallCount += 1
        if shouldFail {
            if let error = errorToThrow {
                throw error
            }
            throw APIError.networkError(NSError(domain: "test", code: -1))
        }
        return racesToReturn
    }
    
    override func fetchNextRace() async throws -> Race? {
        fetchCallCount += 1
        if shouldFail {
            if let error = errorToThrow {
                throw error
            }
            throw APIError.networkError(NSError(domain: "test", code: -1))
        }
        return racesToReturn.first
    }
}

// MARK: - Persistence Model Tests

final class PersistenceModelTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([
            RaceRecord.self,
            CircuitRecord.self,
            SessionRecord.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: false
        )
        
        container = try ModelContainer(
            for: schema,
            configurations: configuration
        )
        context = container.mainContext
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
        try await super.tearDown()
    }
    
    // MARK: - CircuitRecord Tests
    
    func testCircuitRecordCreation() {
        // Given
        let circuit = Circuit.preview
        
        // When
        let record = CircuitRecord(from: circuit)
        
        // Then
        XCTAssertEqual(record.circuitId, circuit.circuitId)
        XCTAssertEqual(record.circuitName, circuit.circuitName)
        XCTAssertEqual(record.locality, circuit.location.locality)
        XCTAssertEqual(record.country, circuit.location.country)
    }
    
    func testCircuitRecordConversion() {
        // Given
        let circuit = Circuit.preview
        let record = CircuitRecord(from: circuit)
        
        // When
        let converted = record.toCircuit()
        
        // Then
        XCTAssertEqual(converted.circuitId, circuit.circuitId)
        XCTAssertEqual(converted.circuitName, circuit.circuitName)
    }
    
    func testCircuitRecordUpdate() {
        // Given
        let original = Circuit.preview
        let record = CircuitRecord(from: original)
        
        let updated = Circuit(
            circuitId: original.circuitId,
            circuitName: "Updated Name",
            location: CircuitLocation(locality: "Updated City", country: "Updated Country")
        )
        
        // When
        record.update(from: updated)
        
        // Then
        XCTAssertEqual(record.circuitName, "Updated Name")
        XCTAssertEqual(record.locality, "Updated City")
    }
    
    // MARK: - RaceRecord Tests
    
    func testRaceRecordCreation() {
        // Given
        let race = Race.preview
        let circuitRecord = CircuitRecord(from: race.circuit)
        context.insert(circuitRecord)
        
        // When
        let record = RaceRecord(from: race, circuit: circuitRecord)
        
        // Then
        XCTAssertEqual(record.id, race.id)
        XCTAssertEqual(record.season, race.season)
        XCTAssertEqual(record.round, race.round)
        XCTAssertEqual(record.raceName, race.raceName)
    }
    
    func testRaceRecordConversion() {
        // Given
        let race = Race.preview
        let circuitRecord = CircuitRecord(from: race.circuit)
        context.insert(circuitRecord)
        
        let record = RaceRecord(from: race, circuit: circuitRecord)
        context.insert(record)
        
        // When
        let converted = record.toRace()
        
        // Then
        XCTAssertNotNil(converted)
        XCTAssertEqual(converted?.id, race.id)
        XCTAssertEqual(converted?.raceName, race.raceName)
    }
    
    func testRaceRecordIsUpcoming() {
        // Given
        let futureDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400 * 30))
        let race = createRace(date: futureDate)
        let circuitRecord = CircuitRecord(from: race.circuit)
        let record = RaceRecord(from: race, circuit: circuitRecord)
        
        // Then
        XCTAssertTrue(record.isUpcoming)
    }
    
    func testRaceRecordMarkCompleted() {
        // Given
        let race = Race.preview
        let circuitRecord = CircuitRecord(from: race.circuit)
        let record = RaceRecord(from: race, circuit: circuitRecord)
        
        XCTAssertFalse(record.isCompleted)
        
        // When
        record.markCompleted()
        
        // Then
        XCTAssertTrue(record.isCompleted)
    }
    
    // MARK: - Helper Methods
    
    private func createRace(date: String) -> Race {
        Race(
            season: "2024",
            round: "1",
            raceName: "Test Grand Prix",
            circuit: Circuit.preview,
            date: date,
            time: "15:00:00Z",
            firstPractice: nil,
            secondPractice: nil,
            thirdPractice: nil,
            qualifying: nil,
            sprint: nil
        )
    }
}

// MARK: - User Preferences Tests

final class UserPreferencesTests: XCTestCase {
    
    func testDefaultPreferences() {
        // When
        let prefs = UserPreferences()
        
        // Then
        XCTAssertTrue(prefs.notificationsEnabled)
        XCTAssertEqual(prefs.themeEnum, .system)
        XCTAssertTrue(prefs.showCompletedRaces)
        XCTAssertTrue(prefs.autoRefreshEnabled)
    }
    
    func testNotificationTimingEnums() {
        // Given
        let prefs = UserPreferences()
        let timings: [NotificationTiming] = [.oneHourBefore, .oneDayBefore]
        
        // When
        prefs.setNotificationTimings(timings)
        
        // Then
        XCTAssertEqual(prefs.notificationTimingEnums, timings)
    }
    
    func testThemeUpdate() {
        // Given
        let prefs = UserPreferences()
        
        // When
        prefs.setTheme(.dark)
        
        // Then
        XCTAssertEqual(prefs.themeEnum, .dark)
    }
    
    func testFavoriteCircuit() {
        // Given
        let prefs = UserPreferences()
        let circuitId = "monaco"
        
        // When
        prefs.addFavoriteCircuit(circuitId)
        
        // Then
        XCTAssertTrue(prefs.isFavoriteCircuit(circuitId))
        
        // When
        prefs.removeFavoriteCircuit(circuitId)
        
        // Then
        XCTAssertFalse(prefs.isFavoriteCircuit(circuitId))
    }
    
    func testShouldNotifyForSessionType() {
        // Given
        let prefs = UserPreferences()
        prefs.setSessionNotificationTypes([.race, .qualifying])
        
        // Then
        XCTAssertTrue(prefs.shouldNotify(for: .race))
        XCTAssertTrue(prefs.shouldNotify(for: .qualifying))
        XCTAssertFalse(prefs.shouldNotify(for: .sprint))
        XCTAssertFalse(prefs.shouldNotify(for: .fp1))
    }
    
    func testIsRefreshDue() {
        // Given
        let prefs = UserPreferences()
        prefs.autoRefreshEnabled = true
        prefs.refreshIntervalMinutes = 60
        
        // When - no last refresh
        XCTAssertTrue(prefs.isRefreshDue)
        
        // When - just refreshed
        prefs.updateLastRefresh()
        XCTAssertFalse(prefs.isRefreshDue)
    }
}
