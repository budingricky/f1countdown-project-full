//
//  LiveActivityAttributes.swift
//  F1Countdown
//
//  Live Activity attributes for Dynamic Island and lock screen
//  Supports CloudKit Push notifications for real-time updates
//

import ActivityKit
import Foundation

// MARK: - Driver Position Model

/// Represents a driver's position in the race
struct DriverPosition: Codable, Hashable, Identifiable {
    var id: String { driverCode }
    
    /// Driver's 3-letter code (e.g., "VER", "HAM")
    let driverCode: String
    
    /// Driver's full name
    let driverName: String
    
    /// Team name
    let teamName: String
    
    /// Current position (1-20)
    let position: Int
    
    /// Gap to leader (e.g., "+1.234" or "LAP 45")
    let gap: String
    
    /// Gap to car ahead
    let gapAhead: String?
    
    /// Current lap number
    let lap: Int?
    
    /// Fastest lap time
    let fastestLap: String?
    
    /// Whether this driver set the fastest lap
    let hasFastestLap: Bool
    
    /// Team color (hex string)
    let teamColor: String
    
    /// Country flag emoji
    let countryFlag: String
    
    // MARK: - Preview Data
    
    static let previewDrivers: [DriverPosition] = [
        DriverPosition(
            driverCode: "VER",
            driverName: "Max Verstappen",
            teamName: "Red Bull Racing",
            position: 1,
            gap: "LAP 45",
            gapAhead: nil,
            lap: 45,
            fastestLap: "1:32.456",
            hasFastestLap: true,
            teamColor: "3671C6",
            countryFlag: "🇳🇱"
        ),
        DriverPosition(
            driverCode: "PER",
            driverName: "Sergio Perez",
            teamName: "Red Bull Racing",
            position: 2,
            gap: "+5.234",
            gapAhead: "+5.234",
            lap: 45,
            fastestLap: "1:33.123",
            hasFastestLap: false,
            teamColor: "3671C6",
            countryFlag: "🇲🇽"
        ),
        DriverPosition(
            driverCode: "HAM",
            driverName: "Lewis Hamilton",
            teamName: "Mercedes",
            position: 3,
            gap: "+12.567",
            gapAhead: "+7.333",
            lap: 45,
            fastestLap: "1:33.456",
            hasFastestLap: false,
            teamColor: "27F4D2",
            countryFlag: "🇬🇧"
        )
    ]
}

// MARK: - Race Status Model

/// Represents the current state of a race
struct RaceStatus: Codable, Hashable {
    /// Current session type
    let sessionType: SessionType
    
    /// Current lap (if race is ongoing)
    let currentLap: Int?
    
    /// Total laps
    let totalLaps: Int?
    
    /// Time elapsed in session
    let timeElapsed: String?
    
    /// Weather condition
    let weather: WeatherCondition?
    
    /// Track temperature in Celsius
    let trackTemp: Int?
    
    /// Air temperature in Celsius
    let airTemp: Int?
    
    /// Whether safety car is deployed
    let safetyCar: Bool
    
    /// Whether virtual safety car is active
    let virtualSafetyCar: Bool
    
    /// Whether red flag is shown
    let redFlag: Bool
    
    /// Session status (started, finished, delayed, etc.)
    let status: SessionStatus
    
    // MARK: - Enums
    
    enum SessionType: String, Codable, Hashable {
        case freePractice1 = "FP1"
        case freePractice2 = "FP2"
        case freePractice3 = "FP3"
        case sprintQualifying = "Sprint Qualifying"
        case sprint = "Sprint"
        case qualifying = "Qualifying"
        case race = "Race"
        
        var displayName: String {
            return rawValue
        }
        
        var shortName: String {
            switch self {
            case .freePractice1: return "FP1"
            case .freePractice2: return "FP2"
            case .freePractice3: return "FP3"
            case .sprintQualifying: return "SQ"
            case .sprint: return "SPR"
            case .qualifying: return "Q"
            case .race: return "RACE"
            }
        }
    }
    
    enum WeatherCondition: String, Codable, Hashable {
        case clear = "Clear"
        case cloudy = "Cloudy"
        case lightRain = "Light Rain"
        case heavyRain = "Heavy Rain"
        
        var icon: String {
            switch self {
            case .clear: return "☀️"
            case .cloudy: return "☁️"
            case .lightRain: return "🌧️"
            case .heavyRain: return "⛈️"
            }
        }
    }
    
    enum SessionStatus: String, Codable, Hashable {
        case notStarted = "Not Started"
        case started = "Started"
        case finished = "Finished"
        case delayed = "Delayed"
        case cancelled = "Cancelled"
        case postponed = "Postponed"
    }
    
    // MARK: - Preview
    
    static let preview = RaceStatus(
        sessionType: .race,
        currentLap: 45,
        totalLaps: 57,
        timeElapsed: "1:15:32",
        weather: .clear,
        trackTemp: 38,
        airTemp: 29,
        safetyCar: false,
        virtualSafetyCar: false,
        redFlag: false,
        status: .started
    )
}

// MARK: - Live Activity Attributes

/// Attributes for F1 Race Live Activity
/// These remain constant throughout the activity's lifetime
struct F1RaceAttributes: ActivityAttributes {
    
    // MARK: - Content State
    
    /// Dynamic state that can be updated via push or local updates
    public struct ContentState: Codable, Hashable {
        /// Race name (e.g., "Bahrain Grand Prix")
        var raceName: String
        
        /// Circuit ID for track visualization
        var circuitId: String
        
        /// Country flag emoji
        var countryFlag: String
        
        /// Current countdown or status text
        var statusText: String
        
        /// Whether the session is currently live
        var isLive: Bool
        
        /// Current session type
        var sessionType: String
        
        /// Progress percentage (0-1) for progress bar
        var progress: Double
        
        /// Time remaining in seconds (for countdown)
        var timeRemaining: TimeInterval?
        
        /// Current race status details
        var raceStatus: RaceStatus?
        
        /// Top drivers' positions (max 5 for performance)
        var topPositions: [DriverPosition]?
        
        /// Timestamp of last update
        var lastUpdated: Date
        
        /// CloudKit push token for remote updates
        var pushToken: String?
        
        // MARK: - Computed Properties
        
        /// Formatted lap progress string
        var lapProgressText: String? {
            guard let status = raceStatus,
                  let current = status.currentLap,
                  let total = status.totalLaps else {
                return nil
            }
            return "LAP \(current)/\(total)"
        }
        
        /// Whether safety car or VSC is active
        var isSafetyCarActive: Bool {
            raceStatus?.safetyCar == true || raceStatus?.virtualSafetyCar == true
        }
        
        /// Whether race is red-flagged
        var isRedFlag: Bool {
            raceStatus?.redFlag == true
        }
        
        // MARK: - Initializers
        
        /// Create initial countdown state
        static func countdownState(
            raceName: String,
            circuitId: String,
            countryFlag: String,
            sessionType: String,
            timeRemaining: TimeInterval
        ) -> ContentState {
            ContentState(
                raceName: raceName,
                circuitId: circuitId,
                countryFlag: countryFlag,
                statusText: formatTimeRemaining(timeRemaining),
                isLive: false,
                sessionType: sessionType,
                progress: 0,
                timeRemaining: timeRemaining,
                raceStatus: nil,
                topPositions: nil,
                lastUpdated: Date(),
                pushToken: nil
            )
        }
        
        /// Create live race state
        static func liveState(
            raceName: String,
            circuitId: String,
            countryFlag: String,
            sessionType: String,
            raceStatus: RaceStatus,
            topPositions: [DriverPosition]
        ) -> ContentState {
            let progress: Double
            if let current = raceStatus.currentLap,
               let total = raceStatus.totalLaps,
               total > 0 {
                progress = Double(current) / Double(total)
            } else {
                progress = 0.5
            }
            
            return ContentState(
                raceName: raceName,
                circuitId: circuitId,
                countryFlag: countryFlag,
                statusText: raceStatus.currentLap.map { "LAP \($0)" } ?? "LIVE",
                isLive: true,
                sessionType: sessionType,
                progress: progress,
                timeRemaining: nil,
                raceStatus: raceStatus,
                topPositions: Array(topPositions.prefix(5)),
                lastUpdated: Date(),
                pushToken: nil
            )
        }
        
        /// Create finished race state
        static func finishedState(
            raceName: String,
            circuitId: String,
            countryFlag: String,
            topPositions: [DriverPosition]
        ) -> ContentState {
            ContentState(
                raceName: raceName,
                circuitId: circuitId,
                countryFlag: countryFlag,
                statusText: "FINISHED",
                isLive: false,
                sessionType: "Race",
                progress: 1.0,
                timeRemaining: nil,
                raceStatus: RaceStatus(
                    sessionType: .race,
                    currentLap: nil,
                    totalLaps: nil,
                    timeElapsed: nil,
                    weather: nil,
                    trackTemp: nil,
                    airTemp: nil,
                    safetyCar: false,
                    virtualSafetyCar: false,
                    redFlag: false,
                    status: .finished
                ),
                topPositions: Array(topPositions.prefix(3)),
                lastUpdated: Date(),
                pushToken: nil
            )
        }
        
        // MARK: - Helper Methods
        
        private static func formatTimeRemaining(_ seconds: TimeInterval) -> String {
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
    
    // MARK: - Attributes
    
    /// Unique identifier for this race activity
    var raceId: String
    
    /// Season year
    var season: Int
    
    /// Round number
    var round: Int
    
    /// Race datetime (for scheduling)
    var raceDateTime: Date
    
    /// Circuit name
    var circuitName: String
    
    // MARK: - Computed Properties
    
    /// Activity ID for CloudKit push notifications
    var activityId: String {
        "\(season)-\(round)-\(raceId)"
    }
}

// MARK: - Push Notification Payload

/// Payload structure for CloudKit Push notifications
struct LiveActivityPushPayload: Codable {
    let raceId: String
    let timestamp: Date
    let state: F1RaceAttributes.ContentState
    
    enum CodingKeys: String, CodingKey {
        case raceId
        case timestamp
        case state
    }
}

// MARK: - Activity Configuration

/// Configuration for Live Activity behavior
struct LiveActivityConfig {
    /// Maximum activity duration (8 hours as per Apple guidelines)
    static let maxDuration: TimeInterval = 8 * 60 * 60
    
    /// Minimum interval between updates (to preserve battery)
    static let minimumUpdateInterval: TimeInterval = 30
    
    /// Stale date offset from activity start
    static let staleDateOffset: TimeInterval = 4 * 60 * 60
    
    /// Whether to enable CloudKit Push notifications
    static var isPushEnabled: Bool {
        // Check if running on device (not simulator)
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
}

// MARK: - Preview Extensions

extension F1RaceAttributes {
    /// Preview attributes for SwiftUI previews
    static let preview = F1RaceAttributes(
        raceId: "2024-1",
        season: 2024,
        round: 1,
        raceDateTime: Date().addingTimeInterval(3600),
        circuitName: "Bahrain International Circuit"
    )
    
    /// Preview content state for countdown
    static let previewCountdownState = ContentState.countdownState(
        raceName: "Bahrain Grand Prix",
        circuitId: "bahrain",
        countryFlag: "🇧🇭",
        sessionType: "Race",
        timeRemaining: 86400 * 2 + 3600 * 5
    )
    
    /// Preview content state for live race
    static let previewLiveState = ContentState.liveState(
        raceName: "Bahrain Grand Prix",
        circuitId: "bahrain",
        countryFlag: "🇧🇭",
        sessionType: "Race",
        raceStatus: .preview,
        topPositions: .previewDrivers
    )
    
    /// Preview content state for finished race
    static let previewFinishedState = ContentState.finishedState(
        raceName: "Bahrain Grand Prix",
        circuitId: "bahrain",
        countryFlag: "🇧🇭",
        topPositions: .previewDrivers
    )
}
