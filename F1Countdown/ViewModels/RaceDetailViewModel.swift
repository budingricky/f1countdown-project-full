import Foundation
import SwiftUI
import Combine

// MARK: - Race Detail View Model

/// ViewModel for displaying detailed information about a single race
@MainActor
final class RaceDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The race being displayed
    @Published private(set) var race: Race?
    
    /// Loading state
    @Published private(set) var isLoading: Bool = false
    
    /// Error message if any
    @Published var errorMessage: String?
    
    /// Notification scheduled state
    @Published var isNotificationScheduled: Bool = false
    
    /// Countdown timer publisher
    @Published private(set) var countdown: String = ""
    
    /// Selected session for expanded view
    @Published var selectedSession: Session?
    
    /// Show session details sheet
    @Published var showingSessionDetails: Bool = false
    
    // MARK: - Private Properties
    
    private let dataService: DataService
    private let preferencesManager: PreferencesManager
    private let raceId: String
    
    /// Timer for countdown updates
    private var countdownTimer: Timer?
    
    /// Time zone for display
    private var displayTimeZone: TimeZone {
        // Use local time zone or circuit time zone based on preference
        let mode = preferencesManager.preferences.timeZoneMode
        if mode == "circuit", let race = race {
            // Try to get circuit time zone (simplified - would need timezone database)
            return .current
        }
        return .current
    }
    
    // MARK: - Computed Properties
    
    /// Race name
    var raceName: String {
        race?.raceName ?? "Race"
    }
    
    /// Circuit name
    var circuitName: String {
        race?.circuit.circuitName ?? ""
    }
    
    /// Circuit location
    var circuitLocation: String {
        guard let race = race else { return "" }
        return "\(race.circuit.location.locality), \(race.circuit.location.country)"
    }
    
    /// Race date formatted
    var formattedRaceDate: String {
        guard let date = race?.raceDateTime else { return "TBA" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.timeZone = displayTimeZone
        return formatter.string(from: date)
    }
    
    /// All sessions sorted chronologically
    var sessions: [Session] {
        race?.sessions ?? []
    }
    
    /// Is this race upcoming
    var isUpcoming: Bool {
        race?.isUpcoming ?? false
    }
    
    /// Is circuit favorited
    var isFavoriteCircuit: Bool {
        guard let circuitId = race?.circuit.circuitId else { return false }
        return preferencesManager.preferences.isFavoriteCircuit(circuitId)
    }
    
    /// Next upcoming session
    var nextSession: Session? {
        let now = Date()
        return sessions.first { session in
            guard let dateTime = session.dateTime else { return false }
            return dateTime > now
        }
    }
    
    /// Round number
    var roundNumber: Int {
        Int(race?.round ?? "0") ?? 0
    }
    
    /// Season year
    var seasonYear: String {
        race?.season ?? ""
    }
    
    // MARK: - Initialization
    
    init(raceId: String, dataService: DataService, preferencesManager: PreferencesManager = .shared) {
        self.raceId = raceId
        self.dataService = dataService
        self.preferencesManager = preferencesManager
        
        // Load race data
        Task {
            await loadRace()
        }
    }
    
    deinit {
        countdownTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Load race data
    func loadRace() async {
        isLoading = true
        defer { isLoading = false }
        
        // Try to get from cache first
        if let cachedRace = await dataService.getCachedRace(id: raceId) {
            race = cachedRace
            startCountdownTimer()
            checkNotificationStatus()
            return
        }
        
        // If not in cache, refresh all data
        do {
            _ = try await dataService.fetchAndCacheRaces(year: Int(race?.season ?? "") ?? 0)
            race = await dataService.getCachedRace(id: raceId)
            startCountdownTimer()
            checkNotificationStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Refresh race data
    func refresh() async {
        await loadRace()
    }
    
    /// Toggle favorite status
    func toggleFavorite() {
        guard let circuitId = race?.circuit.circuitId else { return }
        preferencesManager.toggleFavoriteCircuit(circuitId)
        objectWillChange.send()
    }
    
    /// Schedule notification for this race
    func scheduleNotification() {
        guard let race = race else { return }
        
        // Check if notifications are enabled
        guard preferencesManager.preferences.notificationsEnabled else {
            errorMessage = "Notifications are disabled"
            return
        }
        
        // Schedule notifications for selected sessions
        let timings = preferencesManager.preferences.notificationTimingEnums
        
        for timing in timings {
            guard let interval = timing.timeInterval,
                  let raceDate = race.raceDateTime else { continue }
            
            let notificationDate = raceDate.addingTimeInterval(-interval)
            
            // Only schedule if in the future
            guard notificationDate > Date() else { continue }
            
            // Schedule local notification
            NotificationScheduler.shared.scheduleNotification(
                id: "\(race.id)-\(timing.rawValue)",
                title: race.raceName,
                body: "Race starting \(timing.displayName.lowercased())",
                date: notificationDate
            )
        }
        
        isNotificationScheduled = true
    }
    
    /// Cancel notification for this race
    func cancelNotification() {
        guard let race = race else { return }
        
        let timings = NotificationTiming.allCases
        for timing in timings {
            NotificationScheduler.shared.cancelNotification(
                id: "\(race.id)-\(timing.rawValue)"
            )
        }
        
        isNotificationScheduled = false
    }
    
    /// Toggle notification
    func toggleNotification() {
        if isNotificationScheduled {
            cancelNotification()
        } else {
            scheduleNotification()
        }
    }
    
    /// Show session details
    func showSessionDetails(for session: Session) {
        selectedSession = session
        showingSessionDetails = true
    }
    
    /// Get formatted time for a session
    func formattedSessionTime(_ session: Session) -> String {
        guard let date = session.dateTime else { return "TBA" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = displayTimeZone
        return formatter.string(from: date)
    }
    
    /// Get countdown string for a session
    func sessionCountdown(_ session: Session) -> String {
        guard let dateTime = session.dateTime else { return "TBA" }
        
        let now = Date()
        let interval = dateTime.timeIntervalSince(now)
        
        if interval <= 0 {
            return "Completed"
        }
        
        let days = Int(interval / 86400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Check if session is in the past
    func isSessionCompleted(_ session: Session) -> Bool {
        guard let dateTime = session.dateTime else { return false }
        return dateTime < Date()
    }
    
    /// Share race information
    func shareRaceInfo() -> String {
        guard let race = race else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        let raceDate = race.raceDateTime.map { dateFormatter.string(from: $0) } ?? "TBA"
        
        return """
        🏎️ \(race.raceName)
        📍 \(race.circuit.circuitName), \(race.circuit.location.locality)
        📅 \(raceDate)
        
        Download F1 Countdown to never miss a race!
        """
    }
    
    // MARK: - Private Methods
    
    /// Start countdown timer
    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        
        updateCountdown()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCountdown()
            }
        }
    }
    
    /// Update countdown string
    private func updateCountdown() {
        guard let race = race, let raceDate = race.raceDateTime else {
            countdown = "Date TBA"
            return
        }
        
        let now = Date()
        let interval = raceDate.timeIntervalSince(now)
        
        if interval <= 0 {
            countdown = "Race Started"
            countdownTimer?.invalidate()
            return
        }
        
        let days = Int(interval / 86400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
        
        if days > 0 {
            countdown = String(format: "%02d:%02d:%02d:%02d", days, hours, minutes, seconds)
        } else {
            countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    /// Check notification status
    private func checkNotificationStatus() {
        // Check if any notification is scheduled for this race
        guard let race = race else { return }
        
        let timings = preferencesManager.preferences.notificationTimingEnums
        for timing in timings {
            if NotificationScheduler.shared.isNotificationScheduled(
                id: "\(race.id)-\(timing.rawValue)"
            ) {
                isNotificationScheduled = true
                return
            }
        }
        
        isNotificationScheduled = false
    }
}

// MARK: - Notification Scheduler (Legacy Compatibility)

/// Wrapper for NotificationService providing legacy compatibility
/// Note: Use NotificationService directly for new implementations
@MainActor
final class NotificationScheduler: ObservableObject {
    static let shared = NotificationScheduler()
    
    private let notificationService = NotificationService.shared
    
    private init() {}
    
    func scheduleNotification(id: String, title: String, body: String, date: Date) {
        Task {
            // Map legacy calls to new service
            // Note: This is a simplified mapping for backward compatibility
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            let triggerDate = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: triggerDate,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: id,
                content: content,
                trigger: trigger
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
    
    func cancelNotification(id: String) {
        notificationService.cancelNotification(identifier: id)
    }
    
    func isNotificationScheduled(id: String) -> Bool {
        // Synchronous check for legacy compatibility
        // Returns cached status, actual async check should use NotificationService
        notificationService.scheduledIdentifiers.contains(id)
    }
    
    /// Async version of isNotificationScheduled
    func isNotificationScheduledAsync(id: String) async -> Bool {
        await notificationService.isNotificationScheduled(identifier: id)
    }
}

// MARK: - Preview Support

extension RaceDetailViewModel {
    /// Create a preview view model
    static var preview: RaceDetailViewModel {
        let container = try! ModelContainer(
            for: RaceRecord.self, CircuitRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let dataService = DataService(modelContext: container.mainContext)
        
        // Insert preview data
        let context = container.mainContext
        let circuit = CircuitRecord.preview
        context.insert(circuit)
        let raceRecord = RaceRecord.preview
        raceRecord.circuit = circuit
        context.insert(raceRecord)
        
        return RaceDetailViewModel(raceId: "2024-1", dataService: dataService)
    }
}
