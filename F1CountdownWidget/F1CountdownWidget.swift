//
//  F1CountdownWidget.swift
//  F1CountdownWidget
//
//  Main home screen widgets for F1 countdown
//  Supports: systemSmall, systemMedium, systemLarge
//

import WidgetKit
import SwiftUI
import Intents

// MARK: - Main Widget

struct F1CountdownWidget: Widget {
    let kind: String = "F1CountdownWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: F1TimelineProvider()
        ) { entry in
            F1CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("F1 Countdown")
        .description("Track the countdown to the next Formula 1 race.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget View

struct F1CountdownWidgetView: View {
    var entry: F1TimelineEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (systemSmall)

struct SmallWidgetView: View {
    var entry: F1TimelineEntry
    var race: WidgetRaceData? { entry.nextRace }
    
    var body: some View {
        ZStack {
            // Background
            WidgetBackground()
            
            VStack(spacing: 6) {
                // F1 Logo / Brand
                HStack(spacing: 4) {
                    Text("F1")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    CheckeredAccent(size: 4, rows: 2, columns: 2)
                }
                
                Spacer()
                
                if let race = race {
                    // Countdown
                    VStack(spacing: 2) {
                        Text(race.isLive ? "LIVE" : race.countdownString)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(race.isLive ? F1WidgetColors.f1Yellow : .white)
                        
                        if !race.isLive {
                            Text("to go")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(F1WidgetColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Race info
                    VStack(spacing: 2) {
                        Text(race.countryFlag)
                            .font(.system(size: 14))
                        
                        Text(race.raceName.replacingOccurrences(of: " Grand Prix", with: ""))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                } else {
                    // No upcoming race
                    VStack(spacing: 4) {
                        Text("🏁")
                            .font(.system(size: 32))
                        Text("Season Complete")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(F1WidgetColors.secondaryText)
                    }
                }
            }
            .padding(12)
        }
        .widgetURL(WidgetDeepLinks.countdown())
    }
}

// MARK: - Medium Widget (systemMedium)

struct MediumWidgetView: View {
    var entry: F1TimelineEntry
    var race: WidgetRaceData? { entry.nextRace }
    
    var body: some View {
        ZStack {
            // Background
            WidgetBackground()
            
            if let race = race {
                HStack(spacing: 0) {
                    // Left: Track visualization
                    ZStack {
                        WidgetCircuitShape(circuitId: race.circuitId)
                            .stroke(
                                F1WidgetColors.trackColor(for: race.circuitId),
                                lineWidth: 2
                            )
                            .frame(width: 80, height: 80)
                        
                        WidgetCircuitShape(circuitId: race.circuitId)
                            .fill(
                                F1WidgetColors.trackColor(for: race.circuitId)
                                    .opacity(0.15)
                            )
                            .frame(width: 80, height: 80)
                    }
                    .frame(width: 120)
                    
                    // Right: Race info and countdown
                    VStack(alignment: .leading, spacing: 8) {
                        // Header
                        HStack {
                            Text(race.countryFlag)
                                .font(.system(size: 16))
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("NEXT RACE")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(F1WidgetColors.f1Red)
                                
                                Text(race.raceName)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            
                            Spacer()
                        }
                        
                        // Countdown
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(race.isLive ? "LIVE" : race.countdownString)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(race.isLive ? F1WidgetColors.f1Yellow : .white)
                            
                            if !race.isLive {
                                Text("to go")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(F1WidgetColors.secondaryText)
                            }
                        }
                        
                        // Location
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(F1WidgetColors.tertiaryText)
                            
                            Text(race.locality)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(F1WidgetColors.secondaryText)
                        }
                    }
                    .padding(.trailing, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                // No upcoming race
                VStack(spacing: 8) {
                    Text("🏁")
                        .font(.system(size: 40))
                    
                    Text("Season Complete")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Check back next season!")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(F1WidgetColors.secondaryText)
                }
            }
        }
        .widgetURL(WidgetDeepLinks.countdown())
    }
}

// MARK: - Large Widget (systemLarge)

struct LargeWidgetView: View {
    var entry: F1TimelineEntry
    var races: [WidgetRaceData] {
        Array(entry.upcomingRaces.prefix(3))
    }
    
    var body: some View {
        ZStack {
            // Background
            WidgetBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("F1")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            CheckeredAccent(size: 5, rows: 2, columns: 3)
                        }
                        
                        Text("Upcoming Races")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(F1WidgetColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    if let nextRace = entry.nextRace {
                        // Main countdown
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(nextRace.isLive ? "LIVE NOW" : nextRace.countdownString)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(nextRace.isLive ? F1WidgetColors.f1Yellow : .white)
                            
                            if !nextRace.isLive {
                                Text("to \(nextRace.raceName.replacingOccurrences(of: " Grand Prix", with: ""))")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(F1WidgetColors.secondaryText)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 16)
                
                // Race list
                VStack(spacing: 0) {
                    ForEach(Array(races.enumerated()), id: \.element.id) { index, race in
                        Link(destination: WidgetDeepLinks.raceDetail(raceId: race.id)) {
                            RaceRowView(
                                race: race,
                                isNext: index == 0,
                                showCountdown: index == 0
                            )
                        }
                        .buttonStyle(.plain)
                        
                        if index < races.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .widgetURL(WidgetDeepLinks.schedule())
    }
}

// MARK: - Race Row View

struct RaceRowView: View {
    let race: WidgetRaceData
    let isNext: Bool
    let showCountdown: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Round number or live indicator
            ZStack {
                if isNext {
                    Circle()
                        .fill(F1WidgetColors.f1Red.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    if race.isLive {
                        Circle()
                            .fill(F1WidgetColors.f1Yellow.opacity(0.3))
                            .frame(width: 40, height: 40)
                    }
                }
                
                if race.isLive {
                    Text("LIVE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(F1WidgetColors.f1Yellow)
                } else {
                    Text("R\(race.round)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isNext ? F1WidgetColors.f1Red : F1WidgetColors.secondaryText)
                }
            }
            .frame(width: 40)
            
            // Race info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(race.countryFlag)
                        .font(.system(size: 12))
                    
                    Text(race.raceName.replacingOccurrences(of: " Grand Prix", with: ""))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    Label(race.locality, systemImage: "mappin")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(F1WidgetColors.secondaryText)
                    
                    if let date = formatDate(race.raceDateTime) {
                        Text(date)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(F1WidgetColors.tertiaryText)
                    }
                }
            }
            
            Spacer()
            
            // Countdown or track mini
            if showCountdown && !race.isLive {
                Text(race.shortCountdown)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(F1WidgetColors.f1Red)
            } else if showCountdown && race.isLive {
                Text("LIVE")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(F1WidgetColors.f1Yellow)
            } else {
                // Mini track for other races
                WidgetCircuitShape(circuitId: race.circuitId)
                    .stroke(
                        F1WidgetColors.trackColor(for: race.circuitId).opacity(0.6),
                        lineWidth: 1.5
                    )
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    private func formatDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    F1CountdownWidget()
} timeline: {
    F1TimelineEntry.placeholder
}

#Preview(as: .systemMedium) {
    F1CountdownWidget()
} timeline: {
    F1TimelineEntry.placeholder
}

#Preview(as: .systemLarge) {
    F1CountdownWidget()
} timeline: {
    F1TimelineEntry.placeholder
}
