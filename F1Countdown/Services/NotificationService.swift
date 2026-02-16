import Foundation
import UserNotifications
import Combine

// MARK: - Notification Service Error

/// Errors that can occur in notification operations
enum NotificationServiceError: LocalizedError {
    case authorizationDenied
    case authorizationNotDetermined
    case schedulingFailed(Error)
    case invalidDate
    case notificationNotFound
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Notification authorization was denied. Please enable notifications in Settings."
        case .authorizationNotDetermined:
            return "Notification authorization has not been requested yet."
        case .schedulingFailed(let error):
            return "Failed to schedule notification: \(error.localizedDescription)"
        case .invalidDate:
            return "The notification date is invalid or in the past."
        case .notificationNotFound:
            return "The specified notification was not found."
        }
    }
}

// MARK: - Notification Category

/// Notification categories for F1 app
enum NotificationCategory: String, CaseIterable {
    case race = "F1_RACE_CATEGORY"
    case session = "F1_SESSION_CATEGORY"
}

// MARK: - Notification Action

/// Notification actions for F1 notifications
enum NotificationAction: String, CaseIterable {
    case viewDetails = "VIEW_DETAILS_ACTION"
    case remindLater = "REMIND_LATER_ACTION"
    case dismiss = "DISMISS_ACTION"
}

// MARK: - Notification Identifier

/// Structured notification identifier
struct NotificationIdentifier: Hashable, Codable {
    let raceId: String
    let sessionType: SessionType?
    let timing: NotificationTiming
    
    var identifier: String {
        if let sessionType = sessionType {
            return "race-\(raceId)-\(sessionType.rawValue)-\(timing.rawValue)"
        }
        return "race-\(raceId)-\(timing.rawValue)"
    }
    
    init(raceId: String, sessionType: SessionType? = nil, timing: NotificationTiming) {
        self.raceId = raceId
        self.sessionType = sessionType
        self.timing = timing
    }
    
    /// Parse identifier string
    init?(from string: String) {
        let components = string.components(separatedBy: "-")
        guard components.count >= 3 else { return nil }
        
        // Format: race-{raceId}-{timing} or race-{raceId}-{sessionType}-{timing}
        let raceId: String
        var sessionType: SessionType?
        var timing: NotificationTiming?
        
        if components.count == 3 {
            // Format: race-{raceId}-{timing}
            raceId = components[1]
            timing = NotificationTiming(rawValue: components[2])
        } else if components.count == 4 {
            // Format: race-{raceId}-{sessionType}-{timing}
            raceId = components[1]
            sessionType = SessionType(rawValue: components[2])
            timing = NotificationTiming(rawValue: components[3])
        } else {
            return nil
        }
        
        guard let validTiming = timing else { return nil }
        
        self.raceId = raceId
        self.sessionType = sessionType
        self.timing = validTiming
    }
}

// MARK: - Notification Content

/// Content for a race notification
struct RaceNotificationContent {
    let raceId: String
    let raceName: String
    let circuitName: String
    let sessionType: SessionType
    let sessionTime: Date
    let location: String
    let advanceMinutes: Int
    
    var title: String {
        let timeText = advanceMinutes == 0 ? "Starting Now" : "Starting in \(advanceMinutes) min"
        return "🏎️ \(raceName)"
    }
    
    var body: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let timeString = formatter.string(from: sessionTime)
        
        if advanceMinutes == 0 {
            return "\(sessionType.displayName) is starting now at \(circuitName)!"
        } else {
            return "\(sessionType.displayName) starts in \(advanceMinutes) minutes at \(circuitName). \(timeString)"
        }
    }
    
    var userInfo: [AnyHashable: Any] {
        [
            "raceId": raceId,
            "sessionType": sessionType.rawValue,
            "circuitName": circuitName,
            "sessionTime": sessionTime.timeIntervalSince1970
        ]
    }
}

// MARK: - Notification Service

/// Service for managing local push notifications for F1 races
@MainActor
final class NotificationService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    
    /// Current authorization status
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// Whether notifications are enabled
    @Published private(set) var isEnabled: Bool = false
    
    /// List of scheduled notification identifiers
    @Published private(set) var scheduledIdentifiers: Set<String> = []
    
    // MARK: - Private Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    
    private let remindLaterInterval: TimeInterval = 900 // 15 minutes
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        setupCategories()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                self.authorizationStatus = settings.authorizationStatus
                self.isEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Request notification authorization
    /// - Returns: Whether authorization was granted
    @discardableResult
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
                self.isEnabled = granted
            }
            return granted
        } catch {
            throw NotificationServiceError.schedulingFailed(error)
        }
    }
    
    /// Ensure authorization is granted, requesting if needed
    func ensureAuthorized() async throws {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return
        case .notDetermined:
            let granted = try await requestAuthorization()
            if !granted {
                throw NotificationServiceError.authorizationDenied
            }
        case .denied:
            throw NotificationServiceError.authorizationDenied
        @unknown default:
            throw NotificationServiceError.authorizationNotDetermined
        }
    }
    
    // MARK: - Notification Categories
    
    private func setupCategories() {
        // View Details action
        let viewDetailsAction = UNNotificationAction(
            identifier: NotificationAction.viewDetails.rawValue,
            title: "View Details",
            options: [.foreground]
        )
        
        // Remind Later action
        let remindLaterAction = UNNotificationAction(
            identifier: NotificationAction.remindLater.rawValue,
            title: "Remind in 15 min",
            options: []
        )
        
        // Dismiss action
        let dismissAction = UNNotificationAction(
            identifier: NotificationAction.dismiss.rawValue,
            title: "Dismiss",
            options: [.destructive]
        )
        
        // Race category
        let raceCategory = UNNotificationCategory(
            identifier: NotificationCategory.race.rawValue,
            actions: [viewDetailsAction, remindLaterAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Session category
        let sessionCategory = UNNotificationCategory(
            identifier: NotificationCategory.session.rawValue,
            actions: [viewDetailsAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([raceCategory, sessionCategory])
    }
    
    // MARK: - Schedule Notifications
    
    /// Schedule a notification for a race
    /// - Parameters:
    ///   - race: The race to schedule notification for
    ///   - advanceMinutes: Minutes before the race to notify (15, 30, 60)
    ///   - sessionType: The session type to notify for (default: race)
    func scheduleRaceNotification(
        race: Race,
        advanceMinutes: Int,
        sessionType: SessionType = .race
    ) async throws -> String {
        try await ensureAuthorized()
        
        // Find the session
        let session = race.sessions.first { $0.type == sessionType }
        guard let session = session, let sessionDate = session.dateTime else {
            throw NotificationServiceError.invalidDate
        }
        
        // Calculate notification date
        let notificationDate = sessionDate.addingTimeInterval(-TimeInterval(advanceMinutes * 60))
        
        // Don't schedule for past dates
        guard notificationDate > Date() else {
            throw NotificationServiceError.invalidDate
        }
        
        // Determine timing enum
        let timing: NotificationTiming
        switch advanceMinutes {
        case 0: timing = .atRaceTime
        case 60: timing = .oneHourBefore
        case 120: timing = .twoHoursBefore
        case 1440: timing = .oneDayBefore
        default: timing = .oneHourBefore
        }
        
        // Create identifier
        let identifier = NotificationIdentifier(
            raceId: race.id,
            sessionType: sessionType,
            timing: timing
        )
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "🏎️ \(race.raceName)"
        
        if advanceMinutes == 0 {
            content.body = "\(sessionType.displayName) is starting now at \(race.circuit.circuitName)!"
        } else {
            content.body = "\(sessionType.displayName) starts in \(advanceMinutes) minutes at \(race.circuit.circuitName)."
        }
        
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = sessionType == .race ? 
            NotificationCategory.race.rawValue : 
            NotificationCategory.session.rawValue
        content.userInfo = [
            "raceId": race.id,
            "sessionType": sessionType.rawValue,
            "circuitId": race.circuit.circuitId,
            "sessionTime": sessionDate.timeIntervalSince1970
        ]
        
        // Create trigger
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: notificationDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: identifier.identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule
        do {
            try await notificationCenter.add(request)
            await MainActor.run {
                self.scheduledIdentifiers.insert(identifier.identifier)
            }
            return identifier.identifier
        } catch {
            throw NotificationServiceError.schedulingFailed(error)
        }
    }
    
    /// Schedule multiple notifications for a race based on user preferences
    /// - Parameters:
    ///   - race: The race to schedule notifications for
    ///   - timings: Array of notification timings
    ///   - sessionTypes: Array of session types to notify for
    func scheduleRaceNotifications(
        race: Race,
        timings: [NotificationTiming],
        sessionTypes: [SessionType] = [.race]
    ) async throws -> [String] {
        var identifiers: [String] = []
        
        for timing in timings {
            guard let advanceSeconds = timing.timeInterval else { continue }
            let advanceMinutes = Int(advanceSeconds / 60)
            
            for sessionType in sessionTypes {
                do {
                    let identifier = try await scheduleRaceNotification(
                        race: race,
                        advanceMinutes: advanceMinutes,
                        sessionType: sessionType
                    )
                    identifiers.append(identifier)
                } catch NotificationServiceError.invalidDate {
                    // Skip past dates silently
                    continue
                } catch {
                    throw error
                }
            }
        }
        
        return identifiers
    }
    
    // MARK: - Cancel Notifications
    
    /// Cancel a specific notification
    /// - Parameter identifier: The notification identifier to cancel
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        scheduledIdentifiers.remove(identifier)
    }
    
    /// Cancel all notifications for a specific race
    /// - Parameter raceId: The race ID to cancel notifications for
    func cancelNotifications(forRace raceId: String) {
        let identifiersToRemove = scheduledIdentifiers.filter { $0.contains("race-\(raceId)-") }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: Array(identifiersToRemove))
        scheduledIdentifiers.subtract(identifiersToRemove)
    }
    
    /// Cancel all scheduled notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        scheduledIdentifiers.removeAll()
    }
    
    // MARK: - Get Scheduled Notifications
    
    /// Get all pending notification requests
    func getScheduledNotifications() async -> [UNNotificationRequest] {
        let requests = await notificationCenter.pendingNotificationRequests()
        await MainActor.run {
            self.scheduledIdentifiers = Set(requests.map { $0.identifier })
        }
        return requests
    }
    
    /// Check if a specific notification is scheduled
    /// - Parameter identifier: The notification identifier to check
    /// - Returns: Whether the notification is scheduled
    func isNotificationScheduled(identifier: String) async -> Bool {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.contains { $0.identifier == identifier }
    }
    
    /// Get notifications for a specific race
    /// - Parameter raceId: The race ID to get notifications for
    /// - Returns: Array of notification identifiers for the race
    func getNotifications(forRace raceId: String) async -> [String] {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests
            .filter { $0.identifier.contains("race-\(raceId)-") }
            .map { $0.identifier }
    }
    
    // MARK: - Remind Later
    
    /// Schedule a "remind later" notification
    /// - Parameters:
    ///   - raceId: The race ID
    ///   - sessionType: The session type
    ///   - currentTime: Current session time
    func scheduleRemindLater(raceId: String, sessionType: SessionType, sessionTime: Date) async throws {
        try await ensureAuthorized()
        
        let remindTime = Date().addingTimeInterval(remindLaterInterval)
        
        guard remindTime < sessionTime else {
            // Don't remind after the session has started
            return
        }
        
        let identifier = "remind-\(raceId)-\(sessionType.rawValue)-\(UUID().uuidString)"
        
        let content = UNMutableNotificationContent()
        content.title = "🏎️ Reminder"
        content.body = "Your F1 session is starting soon!"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.session.rawValue
        content.userInfo = [
            "raceId": raceId,
            "sessionType": sessionType.rawValue
        ]
        
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: remindTime
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        await MainActor.run {
            self.scheduledIdentifiers.insert(identifier)
        }
    }
    
    // MARK: - Badge Management
    
    /// Clear the app badge
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    /// Set the app badge
    func setBadge(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification response (user tapped notification)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract race info
        guard let raceId = userInfo["raceId"] as? String else {
            completionHandler()
            return
        }
        
        let sessionTypeRaw = userInfo["sessionType"] as? String
        let sessionType = sessionTypeRaw.flatMap { SessionType(rawValue: $0) }
        
        Task { @MainActor in
            // Handle different actions
            switch response.actionIdentifier {
            case NotificationAction.viewDetails.rawValue:
                // Post notification to navigate to race detail
                NotificationCenter.default.post(
                    name: .notificationViewRaceDetails,
                    object: nil,
                    userInfo: ["raceId": raceId]
                )
                
            case NotificationAction.remindLater.rawValue:
                // Schedule reminder
                if let sessionType = sessionType,
                   let sessionTimeInterval = userInfo["sessionTime"] as? TimeInterval {
                    let sessionTime = Date(timeIntervalSince1970: sessionTimeInterval)
                    try? await NotificationService.shared.scheduleRemindLater(
                        raceId: raceId,
                        sessionType: sessionType,
                        sessionTime: sessionTime
                    )
                }
                
            case NotificationAction.dismiss.rawValue:
                // Just dismiss - nothing extra to do
                break
                
            case UNNotificationDefaultActionIdentifier:
                // User tapped the notification itself (not an action)
                NotificationCenter.default.post(
                    name: .notificationViewRaceDetails,
                    object: nil,
                    userInfo: ["raceId": raceId]
                )
                
            default:
                break
            }
            
            completionHandler()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Notification posted when user taps on a race notification to view details
    static let notificationViewRaceDetails = Notification.Name("notificationViewRaceDetails")
}

// MARK: - Preview Support

extension NotificationService {
    /// Create a preview notification service
    static var preview: NotificationService {
        let service = NotificationService()
        service.authorizationStatus = .authorized
        service.isEnabled = true
        return service
    }
}
