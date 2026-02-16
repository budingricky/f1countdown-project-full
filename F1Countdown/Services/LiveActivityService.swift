//
//  LiveActivityService.swift
//  F1Countdown
//
//  Service for managing Live Activities with CloudKit Push support
//  Handles activity lifecycle, updates, and push token management
//

import ActivityKit
import CloudKit
import Foundation
import UserNotifications
import SwiftUI

// MARK: - Widget Constants (Shared with Widget Extension)

/// App Group identifier for shared data
enum LiveActivityConstants {
    static let appGroupIdentifier = "group.com.f1countdown.shared"
    
    /// UserDefaults suite for widget-main app communication
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
}

// MARK: - Live Activity Service Error

/// Errors that can occur during Live Activity operations
enum LiveActivityError: Error, LocalizedError {
    case activityKitNotAvailable
    case activityAlreadyExists
    case noActiveActivity
    case pushTokenRegistrationFailed
    case updateFailed(Error)
    case invalidRaceData
    
    var errorDescription: String? {
        switch self {
        case .activityKitNotAvailable:
            return "Live Activities are not available on this device"
        case .activityAlreadyExists:
            return "A Live Activity already exists for this race"
        case .noActiveActivity:
            return "No active Live Activity found"
        case .pushTokenRegistrationFailed:
            return "Failed to register for push notifications"
        case .updateFailed(let error):
            return "Failed to update Live Activity: \(error.localizedDescription)"
        case .invalidRaceData:
            return "Invalid race data provided"
        }
    }
}

// MARK: - Live Activity Service

/// Service responsible for managing F1 Live Activities
@MainActor
final class LiveActivityService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = LiveActivityService()
    
    // MARK: - Published Properties
    
    /// Currently active activity
    @Published private(set) var activeActivity: Activity<F1RaceAttributes>?
    
    /// Whether an activity is currently active
    @Published private(set) var hasActiveActivity: Bool = false
    
    /// Push token for remote updates
    @Published private(set) var pushToken: String?
    
    /// Last error that occurred
    @Published private(set) var lastError: LiveActivityError?
    
    // MARK: - Private Properties
    
    /// CloudKit container for push notifications
    private let cloudKitContainer: CKContainer?
    
    /// Timer for countdown updates
    private var updateTimer: Timer?
    
    /// Whether to use CloudKit Push
    private var useCloudKitPush: Bool {
        LiveActivityConfig.isPushEnabled
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize CloudKit container
        self.cloudKitContainer = CKContainer(identifier: "iCloud.com.f1countdown.app")
        
        // Check for existing activities
        Task {
            await checkForExistingActivities()
        }
    }
    
    // MARK: - Public Methods - Activity Lifecycle
    
    /// Start a new Live Activity for a race
    /// - Parameters:
    ///   - race: The race data to display
    ///   - sessionType: The session type (FP1, Qualifying, Race, etc.)
    /// - Returns: The activity ID if successful
    @discardableResult
    func startLiveActivity(
        for race: Race,
        sessionType: RaceStatus.SessionType = .race
    ) async throws -> String {
        // Check if ActivityKit is available
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityError.activityKitNotAvailable
        }
        
        // Check if there's already an active activity
        if hasActiveActivity {
            throw LiveActivityError.activityAlreadyExists
        }
        
        // Get country flag from country name
        let countryFlag = CountryFlagHelper.flag(for: race.circuit.location.country)
        
        // Create attributes
        let attributes = F1RaceAttributes(
            raceId: race.id,
            season: Int(race.season) ?? Calendar.current.component(.year, from: Date()),
            round: Int(race.round) ?? 1,
            raceDateTime: race.raceDateTime ?? Date(),
            circuitName: race.circuit.circuitName
        )
        
        // Create initial state
        let initialState: F1RaceAttributes.ContentState
        
        if let raceDateTime = race.raceDateTime, raceDateTime > Date() {
            // Countdown mode
            let timeRemaining = raceDateTime.timeIntervalSinceNow
            initialState = F1RaceAttributes.ContentState.countdownState(
                raceName: race.raceName,
                circuitId: race.circuit.circuitId,
                countryFlag: countryFlag,
                sessionType: sessionType.displayName,
                timeRemaining: timeRemaining
            )
        } else {
            // Live mode (race has started)
            initialState = F1RaceAttributes.ContentState.liveState(
                raceName: race.raceName,
                circuitId: race.circuit.circuitId,
                countryFlag: countryFlag,
                sessionType: sessionType.displayName,
                raceStatus: RaceStatus.preview,
                topPositions: DriverPosition.previewDrivers
            )
        }
        
        // Configure push type
        let pushType: ActivityPushType? = useCloudKitPush ? .token : nil
        
        // Request activity
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(
                    state: initialState,
                    staleDate: Date().addingTimeInterval(LiveActivityConfig.staleDateOffset)
                ),
                pushType: pushType
            )
            
            // Store reference
            activeActivity = activity
            hasActiveActivity = true
            
            // Register for push notifications if available
            if useCloudKitPush {
                await registerForPushNotifications(activity: activity)
            }
            
            // Start countdown timer if not live
            if !initialState.isLive {
                startCountdownTimer()
            }
            
            print("Started Live Activity: \(activity.id)")
            
            // Save to UserDefaults for persistence
            saveActivityInfo(activity)
            
            return activity.id
        } catch {
            throw LiveActivityError.updateFailed(error)
        }
    }
    
    /// Update the current Live Activity
    /// - Parameters:
    ///   - raceStatus: New race status
    ///   - topPositions: Updated driver positions
    public func updateLiveActivity(
        raceStatus: RaceStatus,
        topPositions: [DriverPosition]
    ) async {
        guard let activity = activeActivity else {
            lastError = .noActiveActivity
            return
        }
        
        let updatedState = F1RaceAttributes.ContentState.liveState(
            raceName: activity.content.state.raceName,
            circuitId: activity.content.state.circuitId,
            countryFlag: activity.content.state.countryFlag,
            sessionType: raceStatus.sessionType.displayName,
            raceStatus: raceStatus,
            topPositions: topPositions
        )
        
        await activity.update(
            ActivityContent(
                state: updatedState,
                staleDate: Date().addingTimeInterval(LiveActivityConfig.staleDateOffset)
            )
        )
        
        // Stop countdown timer if now live
        if updatedState.isLive {
            stopCountdownTimer()
        }
    }
    
    /// Update activity with simple countdown state
    /// - Parameter timeRemaining: Time remaining in seconds
    public func updateCountdown(timeRemaining: TimeInterval) async {
        guard let activity = activeActivity else {
            lastError = .noActiveActivity
            return
        }
        
        var updatedState = activity.content.state
        updatedState.timeRemaining = timeRemaining
        updatedState.statusText = formatTimeRemaining(timeRemaining)
        updatedState.lastUpdated = Date()
        
        await activity.update(
            ActivityContent(
                state: updatedState,
                staleDate: Date().addingTimeInterval(LiveActivityConfig.staleDateOffset)
            )
        )
    }
    
    /// End the current Live Activity
    /// - Parameters:
    ///   - dismissalPolicy: How the activity should be dismissed
    ///   - finalState: Optional final state to display
    public func endLiveActivity(
        dismissalPolicy: ActivityUIDismissalPolicy = .default,
        finalState: F1RaceAttributes.ContentState? = nil
    ) async {
        guard let activity = activeActivity else {
            lastError = .noActiveActivity
            return
        }
        
        // Stop timer
        stopCountdownTimer()
        
        // Create final state if not provided
        let state = finalState ?? F1RaceAttributes.ContentState.finishedState(
            raceName: activity.content.state.raceName,
            circuitId: activity.content.state.circuitId,
            countryFlag: activity.content.state.countryFlag,
            topPositions: activity.content.state.topPositions ?? []
        )
        
        await activity.end(
            ActivityContent(state: state, staleDate: nil),
            dismissalPolicy: dismissalPolicy
        )
        
        // Clear state
        activeActivity = nil
        hasActiveActivity = false
        pushToken = nil
        
        // Clear saved info
        clearActivityInfo()
        
        print("Ended Live Activity: \(activity.id)")
    }
    
    /// End all Live Activities
    public func endAllActivities() async {
        for activity in Activity<F1RaceAttributes>.activities {
            await activity.end(
                ActivityContent(
                    state: F1RaceAttributes.ContentState.finishedState(
                        raceName: activity.content.state.raceName,
                        circuitId: activity.content.state.circuitId,
                        countryFlag: activity.content.state.countryFlag,
                        topPositions: activity.content.state.topPositions ?? []
                    ),
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
        }
        
        // Clear state
        activeActivity = nil
        hasActiveActivity = false
        pushToken = nil
        stopCountdownTimer()
        clearActivityInfo()
    }
    
    // MARK: - Public Methods - Push Notifications
    
    /// Handle push token registration
    /// - Parameter token: The push token data
    public func handlePushToken(_ token: Data) {
        self.pushToken = token.map { String(format: "%02x", $0) }.joined()
        print("Push token received: \(self.pushToken ?? "nil")")
    }
    
    /// Handle remote push notification update
    /// - Parameter payload: The push notification payload
    public func handleRemoteUpdate(_ payload: LiveActivityPushPayload) async {
        // Verify race ID matches
        guard let activity = activeActivity,
              activity.attributes.raceId == payload.raceId else {
            print("Received push for unknown race: \(payload.raceId)")
            return
        }
        
        // Update activity with new state
        await activity.update(
            ActivityContent(
                state: payload.state,
                staleDate: Date().addingTimeInterval(LiveActivityConfig.staleDateOffset)
            )
        )
        
        print("Updated Live Activity from push: \(payload.raceId)")
    }
    
    /// Check if Live Activities are available
    public var areActivitiesAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    // MARK: - Private Methods
    
    /// Check for existing activities on launch
    private func checkForExistingActivities() async {
        let activities = Activity<F1RaceAttributes>.activities
        
        if let existing = activities.first {
            activeActivity = existing
            hasActiveActivity = true
            
            // Get push token if available
            if let token = existing.pushToken {
                self.pushToken = token.map { String(format: "%02x", $0) }.joined()
            }
            
            // Resume timer if needed
            if !existing.content.state.isLive {
                startCountdownTimer()
            }
        }
    }
    
    /// Register for push notifications
    private func registerForPushNotifications(activity: Activity<F1RaceAttributes>) async {
        do {
            // Request notification permission
            let center = UNUserNotificationCenter.current()
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await center.requestAuthorization(options: options)
            
            if !granted {
                print("Notification permission not granted")
                return
            }
            
            // Wait for push token
            for await token in activity.pushTokenUpdates {
                self.pushToken = token.map { String(format: "%02x", $0) }.joined()
                print("Push token registered: \(self.pushToken ?? "nil")")
                break
            }
        } catch {
            print("Failed to register for push notifications: \(error)")
            lastError = .pushTokenRegistrationFailed
        }
    }
    
    /// Start countdown timer for non-live activities
    private func startCountdownTimer() {
        stopCountdownTimer()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let activity = self.activeActivity,
                      !activity.content.state.isLive,
                      let timeRemaining = activity.content.state.timeRemaining else {
                    return
                }
                
                let newTimeRemaining = max(0, timeRemaining - 1)
                
                if newTimeRemaining <= 0 {
                    // Race has started, stop timer
                    self.stopCountdownTimer()
                } else {
                    await self.updateCountdown(timeRemaining: newTimeRemaining)
                }
            }
        }
        
        // Add to common run mode for better scrolling performance
        if let timer = updateTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// Stop countdown timer
    private func stopCountdownTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// Save activity info to UserDefaults
    private func saveActivityInfo(_ activity: Activity<F1RaceAttributes>) {
        let defaults = UserDefaults(suiteName: LiveActivityConstants.appGroupIdentifier)
        defaults?.set(activity.id, forKey: "activeActivityId")
        defaults?.set(activity.attributes.raceId, forKey: "activeRaceId")
    }
    
    /// Clear saved activity info
    private func clearActivityInfo() {
        let defaults = UserDefaults(suiteName: LiveActivityConstants.appGroupIdentifier)
        defaults?.removeObject(forKey: "activeActivityId")
        defaults?.removeObject(forKey: "activeRaceId")
    }
    
    /// Format time remaining for display
    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }
}

// MARK: - Convenience Methods for WidgetRaceData

extension LiveActivityService {
    
    /// Start a Live Activity from WidgetRaceData
    /// - Parameter raceData: The widget race data
    public func startLiveActivity(from raceData: WidgetRaceData) async throws -> String {
        // Create a minimal Race from WidgetRaceData
        let circuit = Circuit(
            circuitId: raceData.circuitId,
            circuitName: raceData.circuitName,
            location: CircuitLocation(
                locality: raceData.locality,
                country: raceData.country
            )
        )
        
        // Create race with required properties
        let season = String(Calendar.current.component(.year, from: raceData.raceDateTime))
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: raceData.raceDateTime).prefix(10)
        
        let race = Race(
            season: season,
            round: String(raceData.round),
            raceName: raceData.raceName,
            circuit: circuit,
            date: String(dateString),
            time: nil,
            firstPractice: nil,
            secondPractice: nil,
            thirdPractice: nil,
            qualifying: nil,
            sprint: nil
        )
        
        return try await startLiveActivity(for: race)
    }
}

// MARK: - Preview Support

extension LiveActivityService {
    /// Create a preview service for SwiftUI previews
    static var preview: LiveActivityService {
        let service = LiveActivityService()
        return service
    }
}

// MARK: - Country Flag Helper

/// Helper for converting country names to flag emojis
enum CountryFlagHelper {
    /// Returns a flag emoji for a country name
    static func flag(for country: String) -> String {
        // Map of country names to flag emojis
        let countryFlags: [String: String] = [
            "Bahrain": "🇧🇭",
            "Saudi Arabia": "🇸🇦",
            "Australia": "🇦🇺",
            "Japan": "🇯🇵",
            "China": "🇨🇳",
            "Miami": "🇺🇸",
            "United States": "🇺🇸",
            "USA": "🇺🇸",
            "Monaco": "🇲🇨",
            "Azerbaijan": "🇦🇿",
            "Canada": "🇨🇦",
            "UK": "🇬🇧",
            "Great Britain": "🇬🇧",
            "United Kingdom": "🇬🇧",
            "Austria": "🇦🇹",
            "France": "🇫🇷",
            "Hungary": "🇭🇺",
            "Belgium": "🇧🇪",
            "Netherlands": "🇳🇱",
            "Italy": "🇮🇹",
            "Singapore": "🇸🇬",
            "Mexico": "🇲🇽",
            "Brazil": "🇧🇷",
            "Las Vegas": "🇺🇸",
            "Abu Dhabi": "🇦🇪",
            "UAE": "🇦🇪",
            "Qatar": "🇶🇦",
            "Spain": "🇪🇸",
            "Germany": "🇩🇪",
            "Portugal": "🇵🇹",
            "Turkey": "🇹🇷",
            "Russia": "🇷🇺",
            "South Korea": "🇰🇷",
            "India": "🇮🇳",
            "Malaysia": "🇲🇾",
            "Thailand": "🇹🇭",
            "Vietnam": "🇻🇳",
            "Morocco": "🇲🇦",
            "Argentina": "🇦🇷",
            "South Africa": "🇿🇦"
        ]
        
        // Try exact match first
        if let flag = countryFlags[country] {
            return flag
        }
        
        // Try case-insensitive match
        let lowercased = country.lowercased()
        for (name, flag) in countryFlags {
            if name.lowercased() == lowercased {
                return flag
            }
        }
        
        // Return default flag if not found
        return "🏁"
    }
}
