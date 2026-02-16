import Foundation
import SwiftData

// MARK: - Notification Settings

/// Notification timing preference
enum NotificationTiming: String, Codable, CaseIterable {
    case atRaceTime = "at_race_time"
    case oneHourBefore = "one_hour"
    case twoHoursBefore = "two_hours"
    case oneDayBefore = "one_day"
    
    var displayName: String {
        switch self {
        case .atRaceTime:
            return "At race time"
        case .oneHourBefore:
            return "1 hour before"
        case .twoHoursBefore:
            return "2 hours before"
        case .oneDayBefore:
            return "1 day before"
        }
    }
    
    /// Time interval in seconds before the session
    var timeInterval: TimeInterval? {
        switch self {
        case .atRaceTime:
            return 0
        case .oneHourBefore:
            return 3600
        case .twoHoursBefore:
            return 7200
        case .oneDayBefore:
            return 86400
        }
    }
}

/// Types of sessions to receive notifications for
enum SessionNotificationType: String, Codable, CaseIterable, OptionSet {
    case race = "race"
    case qualifying = "qualifying"
    case sprint = "sprint"
    case practice = "practice"
    
    var displayName: String {
        switch self {
        case .race:
            return "Race"
        case .qualifying:
            return "Qualifying"
        case .sprint:
            return "Sprint"
        case .practice:
            return "Practice"
        }
    }
}

// MARK: - Theme Settings

/// App theme preference
enum AppTheme: String, Codable, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

// MARK: - User Preferences Model

/// Persistent user preferences for the app
@Model
final class UserPreferences {
    @Attribute(.unique) var id: String
    
    // Notification Settings
    var notificationsEnabled: Bool
    var notificationTimings: [String] // Store NotificationTiming raw values
    var sessionNotificationTypes: [String] // Store SessionNotificationType raw values
    var notifyBeforeSession: Bool
    var soundEnabled: Bool
    
    // Display Settings
    var theme: String // Store AppTheme raw value
    var showCompletedRaces: Bool
    var showSessionTimes: Bool
    var timeZoneMode: String // "local" or "circuit"
    
    // Data Settings
    var autoRefreshEnabled: Bool
    var refreshIntervalMinutes: Int
    var lastRefreshDate: Date?
    
    // Favorite Circuits/Races
    var favoriteCircuitIds: [String]
    var favoriteSeasons: [String]
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init() {
        self.id = "user_preferences"
        self.notificationsEnabled = true
        self.notificationTimings = [NotificationTiming.oneHourBefore.rawValue]
        self.sessionNotificationTypes = [SessionNotificationType.race.rawValue, SessionNotificationType.qualifying.rawValue]
        self.notifyBeforeSession = true
        self.soundEnabled = true
        
        self.theme = AppTheme.system.rawValue
        self.showCompletedRaces = true
        self.showSessionTimes = true
        self.timeZoneMode = "local"
        
        self.autoRefreshEnabled = true
        self.refreshIntervalMinutes = 60
        self.lastRefreshDate = nil
        
        self.favoriteCircuitIds = []
        self.favoriteSeasons = []
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Get notification timings as enum values
    var notificationTimingEnums: [NotificationTiming] {
        notificationTimings.compactMap { NotificationTiming(rawValue: $0) }
    }
    
    /// Set notification timings from enum values
    func setNotificationTimings(_ timings: [NotificationTiming]) {
        notificationTimings = timings.map { $0.rawValue }
        updatedAt = Date()
    }
    
    /// Get session notification types as enum values
    var sessionNotificationTypeEnums: [SessionNotificationType] {
        sessionNotificationTypes.compactMap { SessionNotificationType(rawValue: $0) }
    }
    
    /// Set session notification types from enum values
    func setSessionNotificationTypes(_ types: [SessionNotificationType]) {
        sessionNotificationTypes = types.map { $0.rawValue }
        updatedAt = Date()
    }
    
    /// Get theme as enum value
    var themeEnum: AppTheme {
        AppTheme(rawValue: theme) ?? .system
    }
    
    /// Set theme from enum value
    func setTheme(_ newTheme: AppTheme) {
        theme = newTheme.rawValue
        updatedAt = Date()
    }
    
    /// Check if notifications should be sent for a specific session type
    func shouldNotify(for sessionType: SessionType) -> Bool {
        guard notificationsEnabled else { return false }
        
        let types = sessionNotificationTypeEnums
        switch sessionType {
        case .race:
            return types.contains(.race)
        case .qualifying:
            return types.contains(.qualifying)
        case .sprint:
            return types.contains(.sprint)
        case .fp1, .fp2, .fp3:
            return types.contains(.practice)
        }
    }
    
    /// Add a favorite circuit
    func addFavoriteCircuit(_ circuitId: String) {
        if !favoriteCircuitIds.contains(circuitId) {
            favoriteCircuitIds.append(circuitId)
            updatedAt = Date()
        }
    }
    
    /// Remove a favorite circuit
    func removeFavoriteCircuit(_ circuitId: String) {
        favoriteCircuitIds.removeAll { $0 == circuitId }
        updatedAt = Date()
    }
    
    /// Check if a circuit is favorited
    func isFavoriteCircuit(_ circuitId: String) -> Bool {
        favoriteCircuitIds.contains(circuitId)
    }
    
    /// Update last refresh date
    func updateLastRefresh() {
        lastRefreshDate = Date()
        updatedAt = Date()
    }
    
    /// Check if auto refresh is due
    var isRefreshDue: Bool {
        guard autoRefreshEnabled else { return false }
        guard let lastRefresh = lastRefreshDate else { return true }
        let interval = TimeInterval(refreshIntervalMinutes * 60)
        return Date().timeIntervalSince(lastRefresh) >= interval
    }
}

// MARK: - Preview Data

extension UserPreferences {
    static var preview: UserPreferences {
        let prefs = UserPreferences()
        prefs.setNotificationTimings([.oneHourBefore, .oneDayBefore])
        prefs.setSessionNotificationTypes([.race, .qualifying])
        prefs.setTheme(.dark)
        prefs.favoriteCircuitIds = ["monaco", "silverstone"]
        return prefs
    }
}

// MARK: - Preferences Manager

/// Manages user preferences with SwiftData persistence
@MainActor
final class PreferencesManager: ObservableObject {
    /// Shared singleton instance
    static let shared = PreferencesManager()
    
    /// The SwiftData model context
    private var modelContext: ModelContext?
    
    /// Current user preferences
    @Published private(set) var preferences: UserPreferences
    
    private init() {
        // Create default preferences
        self.preferences = UserPreferences()
    }
    
    /// Configure with model context
    func configure(with context: ModelContext) {
        self.modelContext = context
        loadPreferences()
    }
    
    /// Load preferences from SwiftData
    private func loadPreferences() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate { $0.id == "user_preferences" }
        )
        
        do {
            if let existing = try context.fetch(descriptor).first {
                preferences = existing
            } else {
                // Create new preferences
                context.insert(preferences)
                try context.save()
            }
        } catch {
            // Use default preferences on error
            print("Failed to load preferences: \(error)")
        }
    }
    
    /// Save current preferences
    func save() {
        preferences.updatedAt = Date()
        modelContext?.saveIfChanged()
    }
    
    // MARK: - Convenience Methods
    
    /// Toggle notifications
    func toggleNotifications() {
        preferences.notificationsEnabled.toggle()
        save()
    }
    
    /// Update notification timings
    func updateNotificationTimings(_ timings: [NotificationTiming]) {
        preferences.setNotificationTimings(timings)
        save()
    }
    
    /// Update theme
    func updateTheme(_ theme: AppTheme) {
        preferences.setTheme(theme)
        save()
    }
    
    /// Toggle show completed races
    func toggleShowCompletedRaces() {
        preferences.showCompletedRaces.toggle()
        save()
    }
    
    /// Toggle favorite circuit
    func toggleFavoriteCircuit(_ circuitId: String) {
        if preferences.isFavoriteCircuit(circuitId) {
            preferences.removeFavoriteCircuit(circuitId)
        } else {
            preferences.addFavoriteCircuit(circuitId)
        }
        save()
    }
}

// MARK: - ModelContext Extension

extension ModelContext {
    /// Save only if there are pending changes
    func saveIfChanged() {
        if hasChanges {
            do {
                try save()
            } catch {
                print("Failed to save model context: \(error)")
            }
        }
    }
}
