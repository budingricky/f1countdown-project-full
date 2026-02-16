//
//  TimelineProvider.swift
//  F1CountdownWidget
//
//  Timeline provider for F1 countdown widgets
//  Handles intelligent update scheduling based on race calendar
//

import WidgetKit
import SwiftUI

// MARK: - App Groups Configuration

/// App Group identifier for shared data
enum WidgetConstants {
    static let appGroupIdentifier = "group.com.f1countdown.shared"
    
    /// UserDefaults suite for widget-main app communication
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    /// Keys for shared data
    enum Keys {
        static let nextRace = "nextRace"
        static let upcomingRaces = "upcomingRaces"
        static let lastUpdate = "lastUpdate"
    }
}

// MARK: - Race Data Models for Widget

/// Lightweight race data optimized for widget display
struct WidgetRaceData: Codable, Hashable {
    let id: String
    let raceName: String
    let circuitId: String
    let circuitName: String
    let locality: String
    let country: String
    let countryFlag: String
    let raceDateTime: Date
    let round: Int
    
    /// Time remaining until race start
    var timeRemaining: TimeInterval {
        max(0, raceDateTime.timeIntervalSinceNow)
    }
    
    /// Formatted countdown string
    var countdownString: String {
        let remaining = timeRemaining
        
        if remaining <= 0 {
            return "LIVE"
        }
        
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Short countdown for lock screen
    var shortCountdown: String {
        let remaining = timeRemaining
        
        if remaining <= 0 {
            return "LIVE"
        }
        
        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if days > 0 {
            return "\(days)d"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    /// Whether race is currently live (within 2 hours of start)
    var isLive: Bool {
        let remaining = timeRemaining
        return remaining <= 0 && remaining > -7200
    }
    
    // MARK: - Preview Data
    
    static let preview = WidgetRaceData(
        id: "2024-1",
        raceName: "Bahrain Grand Prix",
        circuitId: "bahrain",
        circuitName: "Bahrain International Circuit",
        locality: "Sakhir",
        country: "Bahrain",
        countryFlag: "🇧🇭",
        raceDateTime: Date().addingTimeInterval(86400 * 3 + 3600 * 5), // 3 days 5 hours from now
        round: 1
    )
    
    static let previewRaces: [WidgetRaceData] = [
        preview,
        WidgetRaceData(
            id: "2024-2",
            raceName: "Saudi Arabian Grand Prix",
            circuitId: "jeddah",
            circuitName: "Jeddah Corniche Circuit",
            locality: "Jeddah",
            country: "Saudi Arabia",
            countryFlag: "🇸🇦",
            raceDateTime: Date().addingTimeInterval(86400 * 10),
            round: 2
        ),
        WidgetRaceData(
            id: "2024-3",
            raceName: "Australian Grand Prix",
            circuitId: "albert_park",
            circuitName: "Albert Park Circuit",
            locality: "Melbourne",
            country: "Australia",
            countryFlag: "🇦🇺",
            raceDateTime: Date().addingTimeInterval(86400 * 17),
            round: 3
        )
    ]
}

// MARK: - Timeline Entry

/// Timeline entry for widget updates
struct F1TimelineEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let nextRace: WidgetRaceData?
    let upcomingRaces: [WidgetRaceData]
    
    /// Static date for placeholder
    static let placeholder = F1TimelineEntry(
        date: Date(),
        configuration: ConfigurationAppIntent(),
        nextRace: .preview,
        upcomingRaces: .previewRaces
    )
}

// MARK: - Configuration Intent

/// Configuration for widget customization
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "F1 Countdown Style"
    static var description: IntentDescription = IntentDescription("Configure your F1 countdown widget")
    
    /// Display mode preference
    enum DisplayMode: String, AppEnum {
        case countdown = "Countdown"
        case schedule = "Schedule"
        
        static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Display Mode")
        static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
            .countdown: "Countdown to Race",
            .schedule: "Race Schedule"
        ]
    }
    
    var displayMode: DisplayMode = .countdown
    
    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$displayMode
        }
    }
}

// MARK: - Timeline Provider

/// Intelligent timeline provider for F1 countdown widgets
struct F1TimelineProvider: IntentTimelineProvider {
    
    typealias Entry = F1TimelineEntry
    typealias Intent = ConfigurationAppIntent
    
    // MARK: - Placeholder
    
    func placeholder(in context: Context) -> F1TimelineEntry {
        .placeholder
    }
    
    // MARK: - Snapshot
    
    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (F1TimelineEntry) -> Void) {
        let entry = F1TimelineEntry(
            date: Date(),
            configuration: configuration,
            nextRace: .preview,
            upcomingRaces: .previewRaces
        )
        completion(entry)
    }
    
    // MARK: - Timeline
    
    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<F1TimelineEntry>) -> Void) {
        let currentDate = Date()
        
        // Load race data from shared UserDefaults
        let nextRace = loadNextRace()
        let upcomingRaces = loadUpcomingRaces()
        
        // Create current entry
        let currentEntry = F1TimelineEntry(
            date: currentDate,
            configuration: configuration,
            nextRace: nextRace,
            upcomingRaces: upcomingRaces
        )
        
        // Determine next update time based on race proximity
        let nextUpdateDate = calculateNextUpdateDate(
            currentDate: currentDate,
            nextRace: nextRace
        )
        
        // Create timeline with intelligent updates
        var entries: [F1TimelineEntry] = [currentEntry]
        
        // Add intermediate entries for countdown updates during race week
        if let race = nextRace {
            let raceInWeek = race.raceDateTime.timeIntervalSince(currentDate) < 86400 * 7
            
            if raceInWeek {
                // More frequent updates during race week
                let updateInterval: TimeInterval = 60 // Update every minute
                
                var nextEntryDate = currentDate.addingTimeInterval(updateInterval)
                while nextEntryDate < nextUpdateDate {
                    let entry = F1TimelineEntry(
                        date: nextEntryDate,
                        configuration: configuration,
                        nextRace: nextRace,
                        upcomingRaces: upcomingRaces
                    )
                    entries.append(entry)
                    nextEntryDate = nextEntryDate.addingTimeInterval(updateInterval)
                }
            }
        }
        
        // Create timeline with policy
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    // MARK: - Private Methods
    
    /// Calculate optimal next update time based on race schedule
    private func calculateNextUpdateDate(currentDate: Date, nextRace: WidgetRaceData?) -> Date {
        guard let race = nextRace else {
            // No upcoming race - update in 1 hour
            return currentDate.addingTimeInterval(3600)
        }
        
        let timeToRace = race.raceDateTime.timeIntervalSince(currentDate)
        
        if timeToRace <= 0 {
            // Race has started - update every minute for live status
            return currentDate.addingTimeInterval(60)
        } else if timeToRace < 3600 {
            // Less than 1 hour to race - update every minute
            return currentDate.addingTimeInterval(60)
        } else if timeToRace < 86400 {
            // Less than 1 day to race - update every 15 minutes
            return currentDate.addingTimeInterval(900)
        } else if timeToRace < 86400 * 7 {
            // Less than 1 week to race - update every hour
            return currentDate.addingTimeInterval(3600)
        } else {
            // More than 1 week - update every 6 hours
            return currentDate.addingTimeInterval(21600)
        }
    }
    
    /// Load next race from shared UserDefaults
    private func loadNextRace() -> WidgetRaceData? {
        guard let defaults = WidgetConstants.sharedDefaults,
              let data = defaults.data(forKey: WidgetConstants.Keys.nextRace) else {
            return .preview // Fallback to preview data
        }
        
        return try? JSONDecoder().decode(WidgetRaceData.self, from: data)
    }
    
    /// Load upcoming races from shared UserDefaults
    private func loadUpcomingRaces() -> [WidgetRaceData] {
        guard let defaults = WidgetConstants.sharedDefaults,
              let data = defaults.data(forKey: WidgetConstants.Keys.upcomingRaces) else {
            return .previewRaces // Fallback to preview data
        }
        
        return (try? JSONDecoder().decode([WidgetRaceData].self, from: data)) ?? .previewRaces
    }
}

// MARK: - Race Data Writer (for main app to use)

/// Helper for main app to write race data to shared storage
struct WidgetRaceDataManager {
    
    /// Save next race data for widget
    static func saveNextRace(_ race: WidgetRaceData) {
        guard let defaults = WidgetConstants.sharedDefaults else { return }
        
        if let data = try? JSONEncoder().encode(race) {
            defaults.set(data, forKey: WidgetConstants.Keys.nextRace)
            defaults.set(Date(), forKey: WidgetConstants.Keys.lastUpdate)
        }
    }
    
    /// Save upcoming races for widget
    static func saveUpcomingRaces(_ races: [WidgetRaceData]) {
        guard let defaults = WidgetConstants.sharedDefaults else { return }
        
        if let data = try? JSONEncoder().encode(races) {
            defaults.set(data, forKey: WidgetConstants.Keys.upcomingRaces)
            defaults.set(Date(), forKey: WidgetConstants.Keys.lastUpdate)
        }
    }
    
    /// Clear all stored race data
    static func clearRaceData() {
        guard let defaults = WidgetConstants.sharedDefaults else { return }
        
        defaults.removeObject(forKey: WidgetConstants.Keys.nextRace)
        defaults.removeObject(forKey: WidgetConstants.Keys.upcomingRaces)
        defaults.removeObject(forKey: WidgetConstants.Keys.lastUpdate)
    }
}
