//
//  F1CountdownWidgetLiveActivity.swift
//  F1CountdownWidget
//
//  Live Activity for Dynamic Island and lock screen
//  Shows real-time countdown and race standings with CloudKit Push support
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Attributes (Widget Target)

/// Attributes for F1 Race Live Activity
/// This is a copy for the widget target - shared models are in F1Countdown/Models/
struct F1RaceAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var raceName: String
        var circuitId: String
        var countryFlag: String
        var statusText: String
        var isLive: Bool
        var sessionType: String
        var progress: Double
        var timeRemaining: TimeInterval?
        var lastUpdated: Date
        var pushToken: String?
        
        // Enhanced data for live races
        var currentLap: Int?
        var totalLaps: Int?
        var safetyCar: Bool
        var redFlag: Bool
        
        // Top 3 drivers for compact view
        var leader: DriverInfo?
        var second: DriverInfo?
        var third: DriverInfo?
        
        // Full standings for expanded view (max 5)
        var standings: [DriverInfo]?
    }
    
    var raceId: String
    var season: Int
    var round: Int
    var raceDateTime: Date
    var circuitName: String
}

/// Driver info for Live Activity display
struct DriverInfo: Codable, Hashable {
    let code: String
    let name: String
    let team: String
    let position: Int
    let gap: String
    let teamColor: String
    let countryFlag: String
}

// MARK: - F1 Widget Colors

struct F1WidgetColors {
    static let f1Red = Color(red: 0.9, green: 0.1, blue: 0.1)
    static let f1Yellow = Color(red: 1.0, green: 0.85, blue: 0.0)
    static let darkBackground = Color(red: 0.06, green: 0.06, blue: 0.06)
    static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let secondaryText = Color(red: 0.7, green: 0.7, blue: 0.7)
    
    static func teamColor(from hex: String) -> Color {
        guard let hexInt = Int(hex, radix: 16) else { return .gray }
        return Color(
            red: Double((hexInt >> 16) & 0xFF) / 255,
            green: Double((hexInt >> 8) & 0xFF) / 255,
            blue: Double(hexInt & 0xFF) / 255
        )
    }
    
    static func trackColor(for circuitId: String) -> Color {
        switch circuitId {
        case "monaco": return .red
        case "silverstone": return .blue
        case "monza": return .green
        case "spa": return .yellow
        case "suzuka": return .white
        default: return .gray
        }
    }
}

// MARK: - Circuit Shape for Widget

struct WidgetCircuitShape: Shape {
    let circuitId: String
    
    func path(in rect: CGRect) -> Path {
        // Simplified circuit outline for widgets
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2
        
        // Create a generic race track shape
        let radius = min(width, height) * 0.35
        let innerRadius = radius * 0.6
        
        // Outer track
        path.addEllipse(in: CGRect(
            x: centerX - radius,
            y: centerY - radius,
            width: radius * 2,
            height: radius * 2
        ))
        
        // Create track groove effect
        path = path.strokedPath(StrokeStyle(lineWidth: 3, lineCap: .round))
        
        return path
    }
}

// MARK: - Live Activity Widget

struct F1CountdownWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: F1RaceAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIslandView(context: context)
        }
    }
}

// MARK: - Lock Screen Live Activity View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<F1RaceAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(context.state.countryFlag)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.sessionType)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(F1WidgetColors.f1Red)
                    
                    Text(context.state.raceName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
                
                Spacer()
                
                statusBadge
            }
            
            // Main content
            if context.state.isLive {
                liveRaceContent
            } else {
                countdownContent
            }
        }
        .padding()
        .activityBackgroundTint(Color.black)
        .activitySystemActionForegroundColor(.white)
    }
    
    // MARK: - Status Badge
    
    @ViewBuilder
    private var statusBadge: some View {
        if context.state.redFlag {
            // Red flag indicator
            HStack(spacing: 3) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 8))
                Text("RED")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(F1WidgetColors.f1Red)
            .cornerRadius(4)
        } else if context.state.safetyCar {
            // Safety car indicator
            HStack(spacing: 3) {
                Image(systemName: "car.fill")
                    .font(.system(size: 8))
                Text("SC")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(4)
        } else if context.state.isLive {
            // Live indicator
            HStack(spacing: 3) {
                Circle()
                    .fill(F1WidgetColors.f1Red)
                    .frame(width: 6, height: 6)
                Text("LIVE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(F1WidgetColors.f1Red)
            }
        }
    }
    
    // MARK: - Countdown Content
    
    @ViewBuilder
    private var countdownContent: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(context.state.statusText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
            
            Text("to go")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(F1WidgetColors.secondaryText)
        }
    }
    
    // MARK: - Live Race Content
    
    @ViewBuilder
    private var liveRaceContent: some View {
        VStack(spacing: 8) {
            // Lap counter
            if let current = context.state.currentLap,
               let total = context.state.totalLaps {
                HStack {
                    Text("LAP \(current)/\(total)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(F1WidgetColors.f1Yellow)
                    
                    Spacer()
                    
                    Text(context.state.statusText)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(F1WidgetColors.secondaryText)
                }
                
                // Progress bar
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.linear)
                    .tint(F1WidgetColors.f1Red)
                    .frame(height: 4)
            }
            
            // Top 3 drivers
            if let leader = context.state.leader {
                HStack(spacing: 12) {
                    driverPositionView(leader, position: 1)
                    
                    if let second = context.state.second {
                        driverPositionView(second, position: 2)
                    }
                    
                    if let third = context.state.third {
                        driverPositionView(third, position: 3)
                    }
                }
            }
        }
    }
    
    // MARK: - Driver Position View
    
    @ViewBuilder
    private func driverPositionView(_ driver: DriverInfo, position: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(position)")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(position == 1 ? F1WidgetColors.f1Yellow : .white)
            
            Text(driver.code)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(F1WidgetColors.teamColor(from: driver.teamColor))
            
            Text(driver.gap)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundColor(F1WidgetColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(F1WidgetColors.cardBackground)
        .cornerRadius(6)
    }
}

// MARK: - Dynamic Island View

struct DynamicIslandView: View {
    let context: ActivityViewContext<F1RaceAttributes>
    
    var body: some View {
        DynamicIsland {
            // Expanded regions
            DynamicIslandExpandedRegion(.leading) {
                leadingRegion
            }
            
            DynamicIslandExpandedRegion(.trailing) {
                trailingRegion
            }
            
            DynamicIslandExpandedRegion(.center) {
                centerRegion
            }
            
            DynamicIslandExpandedRegion(.bottom) {
                bottomRegion
            }
        } compactLeading: {
            compactLeadingView
        } compactTrailing: {
            compactTrailingView
        } minimal: {
            minimalView
        }
    }
    
    // MARK: - Expanded Leading
    
    @ViewBuilder
    private var leadingRegion: some View {
        HStack(spacing: 4) {
            Text("F1")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            if context.state.isLive {
                if context.state.redFlag {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                } else if context.state.safetyCar {
                    Image(systemName: "car.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                } else {
                    Circle()
                        .fill(F1WidgetColors.f1Red)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
    
    // MARK: - Expanded Trailing
    
    @ViewBuilder
    private var trailingRegion: some View {
        if context.state.isLive {
            if let current = context.state.currentLap,
               let total = context.state.totalLaps {
                Text("\(current)/\(total)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(F1WidgetColors.f1Yellow)
            } else {
                Text("LIVE")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(F1WidgetColors.f1Red)
            }
        } else {
            Text(context.state.statusText)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Expanded Center
    
    @ViewBuilder
    private var centerRegion: some View {
        VStack(spacing: 4) {
            // Race name
            HStack(spacing: 4) {
                Text(context.state.countryFlag)
                    .font(.system(size: 14))
                
                Text(context.state.raceName.replacingOccurrences(of: " Grand Prix", with: ""))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            
            // Session type
            Text(context.state.sessionType)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(F1WidgetColors.secondaryText)
            
            // Progress bar for live sessions
            if context.state.isLive {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.linear)
                    .tint(F1WidgetColors.f1Red)
                    .frame(width: 180, height: 4)
            }
        }
    }
    
    // MARK: - Expanded Bottom
    
    @ViewBuilder
    private var bottomRegion: some View {
        if context.state.isLive, let standings = context.state.standings, !standings.isEmpty {
            // Live race standings
            VStack(spacing: 4) {
                ForEach(Array(standings.prefix(3).enumerated()), id: \.element.code) { index, driver in
                    HStack(spacing: 8) {
                        // Position
                        Text("\(driver.position)")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(driver.position == 1 ? F1WidgetColors.f1Yellow : .white)
                            .frame(width: 18)
                        
                        // Team color indicator
                        RoundedRectangle(cornerRadius: 2)
                            .fill(F1WidgetColors.teamColor(from: driver.teamColor))
                            .frame(width: 3, height: 16)
                        
                        // Driver code
                        Text(driver.code)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 32, alignment: .leading)
                        
                        // Country flag
                        Text(driver.countryFlag)
                            .font(.system(size: 10))
                        
                        Spacer()
                        
                        // Gap
                        Text(driver.gap)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(F1WidgetColors.secondaryText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(index % 2 == 0 ? Color.clear : Color.white.opacity(0.05))
                }
            }
            .frame(width: 220)
        } else {
            // Circuit visualization for countdown
            WidgetCircuitShape(circuitId: context.state.circuitId)
                .stroke(
                    F1WidgetColors.trackColor(for: context.state.circuitId).opacity(0.6),
                    lineWidth: 1.5
                )
                .frame(height: 40)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Compact Leading
    
    @ViewBuilder
    private var compactLeadingView: some View {
        HStack(spacing: 2) {
            Text(context.state.countryFlag)
                .font(.system(size: 10))
            
            Text("F1")
                .font(.system(size: 10, weight: .black, design: .rounded))
        }
    }
    
    // MARK: - Compact Trailing
    
    @ViewBuilder
    private var compactTrailingView: some View {
        if context.state.isLive {
            HStack(spacing: 2) {
                Circle()
                    .fill(F1WidgetColors.f1Red)
                    .frame(width: 4, height: 4)
                
                if let leader = context.state.leader {
                    Text(leader.code)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(F1WidgetColors.teamColor(from: leader.teamColor))
                }
            }
        } else {
            Text(context.state.statusText)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }
    
    // MARK: - Minimal
    
    @ViewBuilder
    private var minimalView: some View {
        if context.state.isLive {
            if let leader = context.state.leader {
                Text(leader.code)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(F1WidgetColors.teamColor(from: leader.teamColor))
            } else {
                Circle()
                    .fill(F1WidgetColors.f1Red)
                    .frame(width: 8, height: 8)
            }
        } else {
            Text(context.state.statusText)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }
}

// MARK: - Live Activity Manager

/// Helper for managing Live Activities from widget extension
struct F1LiveActivityManager {
    
    /// Start a new Live Activity for a race
    static func startActivity(
        raceId: String,
        raceName: String,
        circuitId: String,
        countryFlag: String,
        sessionType: String,
        raceDateTime: Date,
        circuitName: String
    ) throws {
        let attributes = F1RaceAttributes(
            raceId: raceId,
            season: Calendar.current.component(.year, from: raceDateTime),
            round: 1,
            raceDateTime: raceDateTime,
            circuitName: circuitName
        )
        
        let timeRemaining = raceDateTime.timeIntervalSinceNow
        let isLive = timeRemaining <= 0
        
        let initialState = F1RaceAttributes.ContentState(
            raceName: raceName,
            circuitId: circuitId,
            countryFlag: countryFlag,
            statusText: formatCountdown(timeRemaining),
            isLive: isLive,
            sessionType: sessionType,
            progress: 0,
            timeRemaining: timeRemaining,
            lastUpdated: Date(),
            pushToken: nil,
            currentLap: nil,
            totalLaps: nil,
            safetyCar: false,
            redFlag: false,
            leader: nil,
            second: nil,
            third: nil,
            standings: nil
        )
        
        let activity = try Activity.request(
            attributes: attributes,
            content: .init(state: initialState, staleDate: nil),
            pushType: .token
        )
        
        print("Started Live Activity: \(activity.id)")
    }
    
    /// Start a Live Activity from WidgetRaceData
    static func startActivity(for race: WidgetRaceData) throws {
        try startActivity(
            raceId: race.id,
            raceName: race.raceName,
            circuitId: race.circuitId,
            countryFlag: race.countryFlag,
            sessionType: "Race",
            raceDateTime: race.raceDateTime,
            circuitName: race.circuitName
        )
    }
    
    /// Update an existing Live Activity with race status
    static func updateActivity(
        raceId: String,
        currentLap: Int,
        totalLaps: Int,
        progress: Double,
        safetyCar: Bool,
        redFlag: Bool,
        standings: [DriverInfo]
    ) async {
        for activity in Activity<F1RaceAttributes>.activities {
            if activity.attributes.raceId == raceId {
                var updatedState = activity.content.state
                updatedState.currentLap = currentLap
                updatedState.totalLaps = totalLaps
                updatedState.progress = progress
                updatedState.safetyCar = safetyCar
                updatedState.redFlag = redFlag
                updatedState.isLive = true
                updatedState.statusText = "LAP \(currentLap)"
                updatedState.lastUpdated = Date()
                
                // Update standings
                if standings.count >= 1 {
                    updatedState.leader = standings[0]
                }
                if standings.count >= 2 {
                    updatedState.second = standings[1]
                }
                if standings.count >= 3 {
                    updatedState.third = standings[2]
                }
                updatedState.standings = Array(standings.prefix(5))
                
                await activity.update(
                    .init(state: updatedState, staleDate: nil)
                )
            }
        }
    }
    
    /// Update an existing Live Activity (legacy method)
    static func updateActivity(
        raceId: String,
        timeRemaining: String,
        isLive: Bool,
        sessionType: String,
        progress: Double
    ) async {
        for activity in Activity<F1RaceAttributes>.activities {
            if activity.attributes.raceId == raceId {
                var updatedState = activity.content.state
                updatedState.statusText = timeRemaining
                updatedState.isLive = isLive
                updatedState.sessionType = sessionType
                updatedState.progress = progress
                updatedState.lastUpdated = Date()
                
                await activity.update(
                    .init(state: updatedState, staleDate: nil)
                )
            }
        }
    }
    
    /// End a Live Activity
    static func endActivity(raceId: String, showResults: Bool = true) async {
        for activity in Activity<F1RaceAttributes>.activities {
            if activity.attributes.raceId == raceId {
                var finalState = activity.content.state
                finalState.isLive = false
                finalState.statusText = "FINISHED"
                finalState.progress = 1.0
                finalState.lastUpdated = Date()
                
                await activity.end(
                    .init(state: finalState, staleDate: nil),
                    dismissalPolicy: .default
                )
            }
        }
    }
    
    /// End all Live Activities
    static func endAllActivities() async {
        for activity in Activity<F1RaceAttributes>.activities {
            await activity.end(
                .init(
                    state: F1RaceAttributes.ContentState(
                        raceName: activity.content.state.raceName,
                        circuitId: activity.content.state.circuitId,
                        countryFlag: activity.content.state.countryFlag,
                        statusText: "",
                        isLive: false,
                        sessionType: "",
                        progress: 0,
                        timeRemaining: nil,
                        lastUpdated: Date(),
                        pushToken: nil,
                        currentLap: nil,
                        totalLaps: nil,
                        safetyCar: false,
                        redFlag: false,
                        leader: nil,
                        second: nil,
                        third: nil,
                        standings: nil
                    ),
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
        }
    }
    
    // MARK: - Helpers
    
    private static func formatCountdown(_ seconds: TimeInterval) -> String {
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

// MARK: - Previews

#Preview("Lock Screen - Countdown") {
    let attributes = F1RaceAttributes(
        raceId: "2024-1",
        season: 2024,
        round: 1,
        raceDateTime: Date().addingTimeInterval(86400 * 2),
        circuitName: "Bahrain International Circuit"
    )
    
    let state = F1RaceAttributes.ContentState(
        raceName: "Bahrain Grand Prix",
        circuitId: "bahrain",
        countryFlag: "🇧🇭",
        statusText: "2d 5h",
        isLive: false,
        sessionType: "Race",
        progress: 0,
        timeRemaining: 86400 * 2 + 3600 * 5,
        lastUpdated: Date(),
        pushToken: nil,
        currentLap: nil,
        totalLaps: nil,
        safetyCar: false,
        redFlag: false,
        leader: nil,
        second: nil,
        third: nil,
        standings: nil
    )
    
    LockScreenLiveActivityView(
        context: ActivityViewContext<F1RaceAttributes>.preview(
            attributes,
            state: state
        )
    )
}

#Preview("Lock Screen - Live Race") {
    let attributes = F1RaceAttributes(
        raceId: "2024-1",
        season: 2024,
        round: 1,
        raceDateTime: Date(),
        circuitName: "Bahrain International Circuit"
    )
    
    let leader = DriverInfo(
        code: "VER",
        name: "Max Verstappen",
        team: "Red Bull Racing",
        position: 1,
        gap: "LAP 45",
        teamColor: "3671C6",
        countryFlag: "🇳🇱"
    )
    
    let second = DriverInfo(
        code: "PER",
        name: "Sergio Perez",
        team: "Red Bull Racing",
        position: 2,
        gap: "+5.234",
        teamColor: "3671C6",
        countryFlag: "🇲🇽"
    )
    
    let third = DriverInfo(
        code: "HAM",
        name: "Lewis Hamilton",
        team: "Mercedes",
        position: 3,
        gap: "+12.567",
        teamColor: "27F4D2",
        countryFlag: "🇬🇧"
    )
    
    let state = F1RaceAttributes.ContentState(
        raceName: "Bahrain Grand Prix",
        circuitId: "bahrain",
        countryFlag: "🇧🇭",
        statusText: "LAP 45",
        isLive: true,
        sessionType: "Race",
        progress: 0.79,
        timeRemaining: nil,
        lastUpdated: Date(),
        pushToken: nil,
        currentLap: 45,
        totalLaps: 57,
        safetyCar: false,
        redFlag: false,
        leader: leader,
        second: second,
        third: third,
        standings: [leader, second, third]
    )
    
    LockScreenLiveActivityView(
        context: ActivityViewContext<F1RaceAttributes>.preview(
            attributes,
            state: state
        )
    )
}

#Preview("Lock Screen - Safety Car") {
    let attributes = F1RaceAttributes(
        raceId: "2024-1",
        season: 2024,
        round: 1,
        raceDateTime: Date(),
        circuitName: "Bahrain International Circuit"
    )
    
    let leader = DriverInfo(
        code: "VER",
        name: "Max Verstappen",
        team: "Red Bull Racing",
        position: 1,
        gap: "LAP 32",
        teamColor: "3671C6",
        countryFlag: "🇳🇱"
    )
    
    let state = F1RaceAttributes.ContentState(
        raceName: "Bahrain Grand Prix",
        circuitId: "bahrain",
        countryFlag: "🇧🇭",
        statusText: "LAP 32",
        isLive: true,
        sessionType: "Race",
        progress: 0.56,
        timeRemaining: nil,
        lastUpdated: Date(),
        pushToken: nil,
        currentLap: 32,
        totalLaps: 57,
        safetyCar: true,
        redFlag: false,
        leader: leader,
        second: nil,
        third: nil,
        standings: [leader]
    )
    
    LockScreenLiveActivityView(
        context: ActivityViewContext<F1RaceAttributes>.preview(
            attributes,
            state: state
        )
    )
}
