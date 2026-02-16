//
//  RaceDetailView.swift
//  F1Countdown
//
//  Detailed view of a race with track visualization and session times
//

import SwiftUI

// MARK: - Race Detail View

/// Detailed view of a race with countdown, track, and session information
struct RaceDetailView: View {
    // MARK: - Properties
    
    let race: Race
    
    /// Track data for this circuit
    private var trackData: TrackData? {
        TrackData.find(by: race.circuit.circuitId)
    }
    
    /// Whether this race is upcoming
    private var isUpcoming: Bool {
        race.isUpcoming
    }
    
    /// Whether this race is in progress (approximate)
    private var isRaceInProgress: Bool {
        guard let raceDate = race.raceDateTime else { return false }
        let now = Date()
        // Consider race in progress for 2 hours after start
        return raceDate <= now && now < raceDate.addingTimeInterval(7200)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Track visualization with countdown
                trackHeaderSection
                
                // Race info card
                raceInfoSection
                
                // Sessions timeline
                sessionsSection
                
                // Circuit information
                circuitInfoSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(race.raceName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                favoriteButton
            }
        }
    }
    
    // MARK: - Track Header Section
    
    @ViewBuilder
    private var trackHeaderSection: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        trackData?.primaryColor.opacity(0.4) ?? Color.red.opacity(0.4),
                        trackData?.primaryColor.opacity(0.1) ?? Color.red.opacity(0.1),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Track visualization
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Track shape
                    if let track = trackData {
                        ZStack {
                            // Outer glow
                            CircuitShape(circuitId: track.circuitId)
                                .stroke(track.primaryColor.opacity(0.3), lineWidth: 20)
                                .blur(radius: 15)
                            
                            // Main track
                            CircuitShape(circuitId: track.circuitId)
                                .stroke(
                                    LinearGradient(
                                        colors: [track.primaryColor, track.secondaryColor, track.primaryColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 4
                                )
                            
                            // Inner highlight
                            CircuitShape(circuitId: track.circuitId)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                .blur(radius: 0.5)
                        }
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.4)
                    } else {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Countdown
                    if let raceDate = race.raceDateTime {
                        if isRaceInProgress {
                            liveCountdown
                        } else if isUpcoming {
                            CountdownView(
                                targetDate: raceDate,
                                accentColor: trackData?.primaryColor ?? Color(red: 0.9, green: 0.1, blue: 0.1)
                            )
                            .padding(.bottom, 20)
                        } else {
                            finishedLabel
                        }
                    }
                }
            }
        }
        .frame(height: 320)
    }
    
    @ViewBuilder
    private var liveCountdown: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 6)
                    )
                    .symbolEffect(.pulse, options: .repeating, isActive: true)
                
                Text("RACE IN PROGRESS")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.15))
            )
        }
    }
    
    @ViewBuilder
    private var finishedLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkered.flag")
                .font(.system(.title3, design: .rounded))
            
            Text("Race Completed")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)
        }
        .foregroundColor(.secondary)
        .padding(.bottom, 20)
    }
    
    // MARK: - Race Info Section
    
    @ViewBuilder
    private var raceInfoSection: some View {
        VStack(spacing: 0) {
            // Race name and round
            HStack {
                Text("Round \(race.round)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.9, green: 0.1, blue: 0.1))
                    )
                
                Spacer()
                
                Text(race.season)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Text(race.raceName)
                .font(.system(.title, design: .rounded))
                .fontWeight(.heavy)
                .foregroundColor(.primary)
                .padding(.top, 12)
            
            // Location
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(.caption))
                Text("\(race.circuit.location.locality), \(race.circuit.location.country)")
                    .font(.system(.subheadline, design: .rounded))
            }
            .foregroundColor(.secondary)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Sessions Section
    
    @ViewBuilder
    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Schedule",
                count: race.sessions.count,
                icon: "calendar"
            )
            .padding(.horizontal)
            .padding(.top)
            
            VStack(spacing: 8) {
                ForEach(race.sessions) { session in
                    SessionRow(
                        session: session,
                        isNext: isNextSession(session)
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    /// Check if this session is the next upcoming one
    private func isNextSession(_ session: Session) -> Bool {
        guard isUpcoming else { return false }
        
        let now = Date()
        let upcomingSessions = race.sessions.filter { ($0.dateTime ?? .distantPast) > now }
        
        if let nextSession = upcomingSessions.sorted(by: { 
            ($0.dateTime ?? .distantFuture) < ($1.dateTime ?? .distantFuture) 
        }).first {
            return session.id == nextSession.id
        }
        
        return false
    }
    
    // MARK: - Circuit Info Section
    
    @ViewBuilder
    private var circuitInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Circuit Information")
                .font(.system(.headline, design: .rounded))
                .padding(.horizontal)
                .padding(.top)
            
            VStack(spacing: 12) {
                // Circuit name
                InfoRow(label: "Circuit", value: race.circuit.circuitName)
                
                // Track stats if available
                if let track = trackData {
                    Divider()
                    
                    HStack(spacing: 20) {
                        StatItem(
                            label: "Length",
                            value: String(format: "%.3f km", track.trackLength),
                            icon: "road.lanes"
                        )
                        
                        StatItem(
                            label: "Turns",
                            value: "\(track.turnCount)",
                            icon: "arrow.turn.down.right"
                        )
                        
                        if let lapRecord = track.lapRecord {
                            StatItem(
                                label: "Lap Record",
                                value: lapRecord,
                                icon: "stopwatch"
                            )
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Toolbar
    
    @ViewBuilder
    private var favoriteButton: some View {
        Button {
            // Toggle favorite action
        } label: {
            Image(systemName: "heart")
                .font(.system(.body, design: .rounded))
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: Session
    var isNext: Bool = false
    
    private var sessionDate: String {
        guard let date = session.dateTime else { return "TBA" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var sessionTime: String {
        guard let date = session.dateTime else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var sessionDay: String {
        guard let date = session.dateTime else { return "---" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Session type icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(sessionTypeColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: sessionIcon)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(sessionTypeColor)
            }
            
            // Session info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(session.type.displayName)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                    
                    if isNext {
                        Text("NEXT")
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.15))
                            )
                    }
                }
                
                Text(sessionDate)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time display
            VStack(alignment: .trailing, spacing: 2) {
                Text(sessionTime)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(sessionDay)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var sessionTypeColor: Color {
        switch session.type {
        case .race:
            return Color(red: 0.9, green: 0.1, blue: 0.1)
        case .qualifying:
            return Color(red: 0.9, green: 0.5, blue: 0.0)
        case .sprint:
            return Color(red: 0.6, green: 0.0, blue: 0.8)
        case .fp1, .fp2, .fp3:
            return Color(red: 0.2, green: 0.5, blue: 0.9)
        }
    }
    
    private var sessionIcon: String {
        switch session.type {
        case .race:
            return "flag.checkered"
        case .qualifying:
            return "timer"
        case .sprint:
            return "bolt.fill"
        case .fp1, .fp2, .fp3:
            return "speedometer"
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(.caption))
                .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
            
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Race Detail") {
    NavigationStack {
        RaceDetailView(race: .preview)
    }
}

#Preview("Session Row") {
    VStack(spacing: 12) {
        SessionRow(session: Session(type: .race, date: "2024-03-02", time: "15:00:00Z"), isNext: true)
        SessionRow(session: Session(type: .qualifying, date: "2024-03-01", time: "16:00:00Z"))
        SessionRow(session: Session(type: .fp1, date: "2024-02-29", time: "11:30:00Z"))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
