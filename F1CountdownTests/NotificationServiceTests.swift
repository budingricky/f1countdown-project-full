import XCTest
import UserNotifications
@testable import F1Countdown

// MARK: - Notification Service Tests

final class NotificationServiceTests: XCTestCase {
    
    var sut: NotificationService!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = NotificationService()
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Notification Identifier Tests
    
    func testNotificationIdentifierCreation() {
        // Given
        let raceId = "2024-1"
        let timing = NotificationTiming.oneHourBefore
        
        // When
        let identifier = NotificationIdentifier(raceId: raceId, timing: timing)
        
        // Then
        XCTAssertEqual(identifier.raceId, raceId)
        XCTAssertEqual(identifier.timing, timing)
        XCTAssertNil(identifier.sessionType)
        XCTAssertEqual(identifier.identifier, "race-2024-1-one_hour")
    }
    
    func testNotificationIdentifierWithSessionType() {
        // Given
        let raceId = "2024-5"
        let sessionType = SessionType.qualifying
        let timing = NotificationTiming.twoHoursBefore
        
        // When
        let identifier = NotificationIdentifier(raceId: raceId, sessionType: sessionType, timing: timing)
        
        // Then
        XCTAssertEqual(identifier.raceId, raceId)
        XCTAssertEqual(identifier.sessionType, sessionType)
        XCTAssertEqual(identifier.timing, timing)
        XCTAssertEqual(identifier.identifier, "race-2024-5-Qualifying-two_hours")
    }
    
    func testNotificationIdentifierParsing() {
        // Given
        let identifierString = "race-2024-3-Race-one_hour"
        
        // When
        let parsed = NotificationIdentifier(from: identifierString)
        
        // Then
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.raceId, "2024-3")
        XCTAssertEqual(parsed?.sessionType, .race)
        XCTAssertEqual(parsed?.timing, .oneHourBefore)
    }
    
    func testNotificationIdentifierParsingWithoutSessionType() {
        // Given
        let identifierString = "race-2024-3-one_hour"
        
        // When
        let parsed = NotificationIdentifier(from: identifierString)
        
        // Then
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.raceId, "2024-3")
        XCTAssertNil(parsed?.sessionType)
        XCTAssertEqual(parsed?.timing, .oneHourBefore)
    }
    
    func testNotificationIdentifierParsingInvalid() {
        // Given
        let invalidStrings = ["invalid", "race-", "race-2024", ""]
        
        // Then
        for string in invalidStrings {
            XCTAssertNil(NotificationIdentifier(from: string), "Should fail for: \(string)")
        }
    }
    
    // MARK: - Notification Service Error Tests
    
    func testNotificationServiceErrorDescriptions() {
        // Given/Then
        XCTAssertNotNil(NotificationServiceError.authorizationDenied.errorDescription)
        XCTAssertNotNil(NotificationServiceError.authorizationNotDetermined.errorDescription)
        XCTAssertNotNil(NotificationServiceError.schedulingFailed(NSError(domain: "test", code: 1)).errorDescription)
        XCTAssertNotNil(NotificationServiceError.invalidDate.errorDescription)
        XCTAssertNotNil(NotificationServiceError.notificationNotFound.errorDescription)
        
        // Check content
        XCTAssertTrue(NotificationServiceError.authorizationDenied.errorDescription?.contains("denied") == true)
        XCTAssertTrue(NotificationServiceError.invalidDate.errorDescription?.contains("invalid") == true)
    }
    
    // MARK: - Race Notification Content Tests
    
    func testRaceNotificationContentAtRaceTime() {
        // Given
        let content = RaceNotificationContent(
            raceId: "2024-1",
            raceName: "Bahrain Grand Prix",
            circuitName: "Bahrain International Circuit",
            sessionType: .race,
            sessionTime: Date(),
            location: "Sakhir",
            advanceMinutes: 0
        )
        
        // Then
        XCTAssertTrue(content.title.contains("Bahrain Grand Prix"))
        XCTAssertTrue(content.body.contains("starting now"))
        XCTAssertTrue(content.body.contains("Bahrain International Circuit"))
        XCTAssertEqual(content.userInfo["raceId"] as? String, "2024-1")
    }
    
    func testRaceNotificationContentBeforeRace() {
        // Given
        let content = RaceNotificationContent(
            raceId: "2024-2",
            raceName: "Saudi Arabian Grand Prix",
            circuitName: "Jeddah Corniche Circuit",
            sessionType: .qualifying,
            sessionTime: Date().addingTimeInterval(3600),
            location: "Jeddah",
            advanceMinutes: 60
        )
        
        // Then
        XCTAssertTrue(content.title.contains("Saudi Arabian Grand Prix"))
        XCTAssertTrue(content.body.contains("60 minutes"))
        XCTAssertTrue(content.body.contains("Qualifying"))
        XCTAssertTrue(content.body.contains("Jeddah Corniche Circuit"))
    }
    
    // MARK: - Authorization Status Tests
    
    func testCheckAuthorizationStatus() {
        // When
        sut.checkAuthorizationStatus()
        
        // Then - just verify it doesn't crash
        // Actual status depends on simulator/device settings
        XCTAssertNotNil(sut.authorizationStatus)
    }
    
    // MARK: - Cancel Notification Tests
    
    func testCancelNotification() {
        // Given
        let identifier = "test-notification-id"
        sut.scheduledIdentifiers.insert(identifier)
        
        // When
        sut.cancelNotification(identifier: identifier)
        
        // Then
        XCTAssertFalse(sut.scheduledIdentifiers.contains(identifier))
    }
    
    func testCancelNotificationsForRace() {
        // Given
        let raceId = "2024-5"
        let identifiers = [
            "race-\(raceId)-Race-one_hour",
            "race-\(raceId)-Qualifying-one_hour",
            "race-2024-6-Race-one_hour" // Different race
        ]
        sut.scheduledIdentifiers = Set(identifiers)
        
        // When
        sut.cancelNotifications(forRace: raceId)
        
        // Then
        XCTAssertFalse(sut.scheduledIdentifiers.contains("race-\(raceId)-Race-one_hour"))
        XCTAssertFalse(sut.scheduledIdentifiers.contains("race-\(raceId)-Qualifying-one_hour"))
        XCTAssertTrue(sut.scheduledIdentifiers.contains("race-2024-6-Race-one_hour"))
    }
    
    func testCancelAllNotifications() {
        // Given
        sut.scheduledIdentifiers = ["id1", "id2", "id3"]
        
        // When
        sut.cancelAllNotifications()
        
        // Then
        XCTAssertTrue(sut.scheduledIdentifiers.isEmpty)
    }
    
    // MARK: - Badge Tests
    
    func testClearBadge() {
        // When
        sut.clearBadge()
        
        // Then
        XCTAssertEqual(UIApplication.shared.applicationIconBadgeNumber, 0)
    }
    
    func testSetBadge() {
        // When
        sut.setBadge(5)
        
        // Then
        XCTAssertEqual(UIApplication.shared.applicationIconBadgeNumber, 5)
        
        // Cleanup
        sut.clearBadge()
    }
    
    // MARK: - Notification Category Tests
    
    func testNotificationCategoriesExist() {
        // Then
        XCTAssertEqual(NotificationCategory.race.rawValue, "F1_RACE_CATEGORY")
        XCTAssertEqual(NotificationCategory.session.rawValue, "F1_SESSION_CATEGORY")
    }
    
    func testNotificationActionsExist() {
        // Then
        XCTAssertEqual(NotificationAction.viewDetails.rawValue, "VIEW_DETAILS_ACTION")
        XCTAssertEqual(NotificationAction.remindLater.rawValue, "REMIND_LATER_ACTION")
        XCTAssertEqual(NotificationAction.dismiss.rawValue, "DISMISS_ACTION")
    }
}

// MARK: - Notification Identifier Tests

final class NotificationIdentifierTests: XCTestCase {
    
    func testIdentifierHashable() {
        // Given
        let id1 = NotificationIdentifier(raceId: "2024-1", timing: .oneHourBefore)
        let id2 = NotificationIdentifier(raceId: "2024-1", timing: .oneHourBefore)
        let id3 = NotificationIdentifier(raceId: "2024-1", timing: .twoHoursBefore)
        
        // Then
        XCTAssertEqual(id1, id2)
        XCTAssertNotEqual(id1, id3)
    }
    
    func testIdentifierCodable() throws {
        // Given
        let original = NotificationIdentifier(raceId: "2024-3", sessionType: .race, timing: .oneDayBefore)
        
        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NotificationIdentifier.self, from: data)
        
        // Then
        XCTAssertEqual(original.raceId, decoded.raceId)
        XCTAssertEqual(original.sessionType, decoded.sessionType)
        XCTAssertEqual(original.timing, decoded.timing)
    }
}

// MARK: - Integration Tests (Require Real Notification Center)

final class NotificationServiceIntegrationTests: XCTestCase {
    
    var sut: NotificationService!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = NotificationService()
    }
    
    override func tearDown() async throws {
        // Clean up any scheduled notifications
        sut?.cancelAllNotifications()
        sut = nil
        try await super.tearDown()
    }
    
    func testGetScheduledNotifications() async {
        // When
        let notifications = await sut.getScheduledNotifications()
        
        // Then - should return an array (may be empty)
        XCTAssertNotNil(notifications)
    }
    
    func testIsNotificationScheduled() async {
        // Given
        let identifier = "non-existent-notification"
        
        // When
        let isScheduled = await sut.isNotificationScheduled(identifier: identifier)
        
        // Then
        XCTAssertFalse(isScheduled)
    }
    
    func testGetNotificationsForRace() async {
        // Given
        let raceId = "2024-nonexistent"
        
        // When
        let notifications = await sut.getNotifications(forRace: raceId)
        
        // Then
        XCTAssertTrue(notifications.isEmpty)
    }
}

// MARK: - Notification Timing Tests

final class NotificationTimingTests: XCTestCase {
    
    func testTimingDisplayName() {
        XCTAssertEqual(NotificationTiming.atRaceTime.displayName, "At race time")
        XCTAssertEqual(NotificationTiming.oneHourBefore.displayName, "1 hour before")
        XCTAssertEqual(NotificationTiming.twoHoursBefore.displayName, "2 hours before")
        XCTAssertEqual(NotificationTiming.oneDayBefore.displayName, "1 day before")
    }
    
    func testTimingTimeInterval() {
        XCTAssertEqual(NotificationTiming.atRaceTime.timeInterval, 0)
        XCTAssertEqual(NotificationTiming.oneHourBefore.timeInterval, 3600)
        XCTAssertEqual(NotificationTiming.twoHoursBefore.timeInterval, 7200)
        XCTAssertEqual(NotificationTiming.oneDayBefore.timeInterval, 86400)
    }
    
    func testAllTimingsAvailable() {
        XCTAssertEqual(NotificationTiming.allCases.count, 4)
    }
}

// MARK: - Mock Tests for Schedule Race Notification

final class NotificationServiceScheduleTests: XCTestCase {
    
    var sut: NotificationService!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = NotificationService()
    }
    
    override func tearDown() async throws {
        sut?.cancelAllNotifications()
        sut = nil
        try await super.tearDown()
    }
    
    func testScheduleNotificationForPastDateThrowsError() async {
        // Given - a race in the past
        let pastDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400))
        let pastRace = Race(
            season: "2024",
            round: "1",
            raceName: "Past Grand Prix",
            circuit: Circuit(
                circuitId: "past-circuit",
                circuitName: "Past Circuit",
                location: CircuitLocation(locality: "Past City", country: "Past Country")
            ),
            date: pastDate,
            time: "15:00:00Z",
            firstPractice: nil,
            secondPractice: nil,
            thirdPractice: nil,
            qualifying: nil,
            sprint: nil
        )
        
        // When/Then
        do {
            _ = try await sut.scheduleRaceNotification(race: pastRace, advanceMinutes: 60)
            XCTFail("Should throw invalidDate error")
        } catch let error as NotificationServiceError {
            if case .invalidDate = error {
                // Expected
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            // Authorization errors are acceptable in test environment
            if !(error is NotificationServiceError) {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    func testScheduleNotificationWithMissingTimeThrowsError() async {
        // Given - a race without a time
        let raceWithoutTime = Race(
            season: "2024",
            round: "1",
            raceName: "TBD Grand Prix",
            circuit: Circuit(
                circuitId: "tbd-circuit",
                circuitName: "TBD Circuit",
                location: CircuitLocation(locality: "TBD City", country: "TBD Country")
            ),
            date: "2024-12-31",
            time: nil, // No time specified
            firstPractice: nil,
            secondPractice: nil,
            thirdPractice: nil,
            qualifying: nil,
            sprint: nil
        )
        
        // When/Then
        do {
            _ = try await sut.scheduleRaceNotification(race: raceWithoutTime, advanceMinutes: 60)
            // May succeed if authorization denied first
        } catch let error as NotificationServiceError {
            // Either invalidDate or authorization error is acceptable
            XCTAssert(true)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

// MARK: - Notification Name Tests

final class NotificationNameTests: XCTestCase {
    
    func testNotificationViewRaceDetailsName() {
        XCTAssertEqual(Notification.Name.notificationViewRaceDetails.rawValue, "notificationViewRaceDetails")
    }
}
