//
//  LockScreenWidget.swift
//  F1CountdownWidget
//
//  Lock screen widgets for F1 countdown
//  Supports: accessoryCircular, accessoryRectangular
//

import WidgetKit
import SwiftUI

// MARK: - Lock Screen Widget

struct LockScreenWidget: Widget {
    let kind: String = "F1LockScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("F1 Countdown")
        .description("Quick countdown to the next race.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Lock Screen Timeline Provider

struct LockScreenTimelineProvider: TimelineProvider {
    typealias Entry = LockScreenEntry
    
    func placeholder(in context: Context) -> LockScreenEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> Void) {
        completion(.placeholder)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> Void) {
        let currentDate = Date()
        
        // Load race data
        let nextRace = loadNextRace()
        
        // Create current entry
        let currentEntry = LockScreenEntry(
            date: currentDate,
            nextRace: nextRace
        )
        
        // Calculate next update time
        let nextUpdateDate = calculateNextUpdateDate(
            currentDate: currentDate,
            nextRace: nextRace
        )
        
        // Create timeline
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    private func calculateNextUpdateDate(currentDate: Date, nextRace: WidgetRaceData?) -> Date {
        guard let race = nextRace else {
            return currentDate.addingTimeInterval(3600)
        }
        
        let timeToRace = race.raceDateTime.timeIntervalSince(currentDate)
        
        if timeToRace <= 0 {
            return currentDate.addingTimeInterval(60) // Live - update every minute
        } else if timeToRace < 3600 {
            return currentDate.addingTimeInterval(60) // Less than 1 hour - update every minute
        } else if timeToRace < 86400 {
            return currentDate.addingTimeInterval(300) // Less than 1 day - update every 5 minutes
        } else {
            return currentDate.addingTimeInterval(1800) // Update every 30 minutes
        }
    }
    
    private func loadNextRace() -> WidgetRaceData? {
        guard let defaults = WidgetConstants.sharedDefaults,
              let data = defaults.data(forKey: WidgetConstants.Keys.nextRace) else {
            return .preview
        }
        return try? JSONDecoder().decode(WidgetRaceData.self, from: data)
    }
}

// MARK: - Lock Screen Entry

struct LockScreenEntry: TimelineEntry {
    let date: Date
    let nextRace: WidgetRaceData?
    
    static let placeholder = LockScreenEntry(
        date: Date(),
        nextRace: .preview
    )
}

// MARK: - Lock Screen Widget View

struct LockScreenWidgetView: View {
    var entry: LockScreenEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        default:
            CircularLockScreenView(entry: entry)
        }
    }
}

// MARK: - Circular Lock Screen Widget

struct CircularLockScreenView: View {
    var entry: LockScreenEntry
    var race: WidgetRaceData? { entry.nextRace }
    
    var body: some View {
        ZStack {
            // Background gauge
            AccessoryWidgetBackground()
            
            if let race = race {
                VStack(spacing: 1) {
                    // F1 branding
                    if race.isLive {
                        // Live indicator with pulsing effect
                        HStack(spacing: 2) {
                            Circle()
                                .fill(F1WidgetColors.f1Red)
                                .frame(width: 4, height: 4)
                            Text("LIVE")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                        }
                    } else {
                        Text("F1")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                    }
                    
                    // Countdown
                    Text(race.isLive ? "NOW" : race.shortCountdown)
                        .font(.system(size: race.isLive ? 12 : 14, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .widgetURL(WidgetDeepLinks.countdown())
            } else {
                VStack(spacing: 1) {
                    Text("🏁")
                        .font(.system(size: 14))
                    Text("Done")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                }
            }
        }
    }
}

// MARK: - Rectangular Lock Screen Widget

struct RectangularLockScreenView: View {
    var entry: LockScreenEntry
    var race: WidgetRaceData? { entry.nextRace }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let race = race {
                // Header with race name
                HStack {
                    Text(race.countryFlag)
                        .font(.system(size: 14))
                    
                    Text(race.raceName.replacingOccurrences(of: " Grand Prix", with: ""))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    if race.isLive {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(F1WidgetColors.f1Red)
                                .frame(width: 5, height: 5)
                            Text("LIVE")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                        }
                    }
                }
                
                // Countdown display
                if !race.isLive {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(race.countdownString)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        
                        Text("to go")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Location and date
                HStack(spacing: 6) {
                    Label(race.locality, systemImage: "mappin")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                    
                    if let date = formatDate(race.raceDateTime) {
                        Text(date)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                }
                .foregroundColor(.secondary)
            } else {
                // No upcoming race
                HStack {
                    Text("🏁")
                        .font(.system(size: 16))
                    Text("Season Complete")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
            }
        }
        .widgetURL(WidgetDeepLinks.countdown())
    }
    
    private func formatDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview(as: .accessoryCircular) {
    LockScreenWidget()
} timeline: {
    LockScreenEntry.placeholder
}

#Preview(as: .accessoryRectangular) {
    LockScreenWidget()
} timeline: {
    LockScreenEntry.placeholder
}
