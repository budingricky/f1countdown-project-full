//
//  RaceCardView.swift
//  F1Countdown
//
//  Race card component displaying race info with countdown and track thumbnail
//

import SwiftUI

// MARK: - Race Card View

/// A card displaying race information with countdown and track thumbnail
struct RaceCardView: View {
    // MARK: - Properties
    
    /// The race to display
    let race: Race
    
    /// Card style variant
    var style: CardStyle = .standard
    
    /// Whether this card is selected
    var isSelected: Bool = false
    
    /// Tap action
    var onTap: ((Race) -> Void)?
    
    /// Track data for this race's circuit
    private var trackData: TrackData? {
        TrackData.find(by: race.circuit.circuitId)
    }
    
    /// Whether the race is in the past
    private var isPast: Bool {
        guard let date = race.raceDateTime else { return false }
        return date < Date()
    }
    
    /// Whether the race is the next upcoming
    private var isNext: Bool {
        race.isUpcoming
    }
    
    // MARK: - Card Style
    
    enum CardStyle {
        case standard
        case compact
        case featured
        
        var height: CGFloat {
            switch self {
            case .standard: return 140
            case .compact: return 100
            case .featured: return 220
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch style {
            case .standard:
                standardCard
            case .compact:
                compactCard
            case .featured:
                featuredCard
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?(race)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view details")
    }
    
    // MARK: - Card Variants
    
    @ViewBuilder
    private var standardCard: some View {
        HStack(spacing: 0) {
            // Track thumbnail
            trackThumbnail
                .frame(width: 120)
            
            // Race info
            VStack(alignment: .leading, spacing: 8) {
                // Header with round number
                HStack {
                    Text("R\(race.round)")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.9, green: 0.1, blue: 0.1))
                        )
                    
                    if isNext {
                        Text("NEXT")
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.15))
                            )
                    }
                    
                    Spacer()
                }
                
                // Race name
                Text(race.raceName)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(.caption2))
                    Text("\(race.circuit.location.locality), \(race.circuit.location.country)")
                        .font(.system(.caption, design: .rounded))
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Countdown or date
                if let date = race.raceDateTime, !isPast {
                    CountdownView(
                        targetDate: date,
                        accentColor: trackData?.primaryColor ?? Color(red: 0.9, green: 0.1, blue: 0.1),
                        isCompact: true
                    )
                } else {
                    raceDateLabel
                }
            }
            .padding(12)
        }
        .frame(height: style.height)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color(red: 0.9, green: 0.1, blue: 0.1) : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var compactCard: some View {
        HStack(spacing: 12) {
            // Track mini thumbnail
            ZStack {
                if let track = trackData {
                    CircuitShape(circuitId: track.circuitId)
                        .stroke(track.primaryColor, lineWidth: 2)
                        .frame(width: 50, height: 50)
                } else {
                    Image(systemName: "flag.checkered")
                        .font(.system(.title2))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 60, height: 60)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Race info
            VStack(alignment: .leading, spacing: 4) {
                Text(race.raceName)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(race.circuit.location.locality), \(race.circuit.location.country)")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let date = race.raceDateTime, !isPast {
                    CountdownView(
                        targetDate: date,
                        accentColor: trackData?.primaryColor ?? Color(red: 0.9, green: 0.1, blue: 0.1),
                        isCompact: true
                    )
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(.caption))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(height: style.height)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color(red: 0.9, green: 0.1, blue: 0.1) : Color.clear, lineWidth: 2)
        )
    }
    
    @ViewBuilder
    private var featuredCard: some View {
        VStack(spacing: 0) {
            // Track visualization (top half)
            GeometryReader { geometry in
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [
                            trackData?.primaryColor.opacity(0.3) ?? Color.red.opacity(0.3),
                            trackData?.primaryColor.opacity(0.1) ?? Color.red.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Track shape
                    if let track = trackData {
                        ZStack {
                            // Glow
                            CircuitShape(circuitId: track.circuitId)
                                .stroke(track.primaryColor.opacity(0.5), lineWidth: 12)
                                .blur(radius: 8)
                            
                            // Main track
                            CircuitShape(circuitId: track.circuitId)
                                .stroke(
                                    LinearGradient(
                                        colors: [track.primaryColor, track.secondaryColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 4
                                )
                        }
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.8)
                    }
                    
                    // "NEXT RACE" badge
                    VStack {
                        HStack {
                            Spacer()
                            
                            Text("NEXT RACE")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.9, green: 0.1, blue: 0.1))
                                )
                                .padding(12)
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: style.height * 0.5)
            
            // Race info (bottom half)
            VStack(spacing: 8) {
                Text(race.raceName)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.heavy)
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(.caption))
                    Text("\(race.circuit.location.locality), \(race.circuit.location.country)")
                        .font(.system(.subheadline, design: .rounded))
                }
                .foregroundColor(.secondary)
                
                // Countdown
                if let date = race.raceDateTime, !isPast {
                    CountdownView(
                        targetDate: date,
                        accentColor: trackData?.primaryColor ?? Color(red: 0.9, green: 0.1, blue: 0.1)
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color(red: 0.9, green: 0.1, blue: 0.1) : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var trackThumbnail: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        trackData?.primaryColor.opacity(0.15) ?? Color.red.opacity(0.15),
                        trackData?.primaryColor.opacity(0.05) ?? Color.red.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Track shape
                if let track = trackData {
                    ZStack {
                        // Glow effect
                        CircuitShape(circuitId: track.circuitId)
                            .stroke(track.primaryColor.opacity(0.3), lineWidth: 10)
                            .blur(radius: 4)
                        
                        // Main track line
                        CircuitShape(circuitId: track.circuitId)
                            .stroke(
                                LinearGradient(
                                    colors: [track.primaryColor, track.secondaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 3
                            )
                    }
                    .frame(width: geometry.size.width * 0.85, height: geometry.size.height * 0.7)
                } else {
                    // Fallback icon
                    Image(systemName: "flag.checkered")
                        .font(.system(.largeTitle))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        ZStack {
            Color(.secondarySystemGroupedBackground)
            
            // Subtle gradient overlay for next race
            if isNext {
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.05),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    @ViewBuilder
    private var raceDateLabel: some View {
        if let date = race.raceDateTime {
            Text(formatDate(date))
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var accessibilityLabel: String {
        var label = "\(race.raceName), round \(race.round), at \(race.circuit.location.locality), \(race.circuit.location.country)"
        
        if let date = race.raceDateTime {
            if isPast {
                label += ", finished"
            } else {
                label += ", starts in \(days) days, \(hours) hours, \(minutes) minutes"
            }
        }
        
        return label
    }
    
    private var days: Int {
        guard let date = race.raceDateTime else { return 0 }
        return max(0, Int(date.timeIntervalSinceNow / 86400))
    }
    
    private var hours: Int {
        guard let date = race.raceDateTime else { return 0 }
        return max(0, Int((date.timeIntervalSinceNow.truncatingRemainder(dividingBy: 86400)) / 3600))
    }
    
    private var minutes: Int {
        guard let date = race.raceDateTime else { return 0 }
        return max(0, Int((date.timeIntervalSinceNow.truncatingRemainder(dividingBy: 3600)) / 60))
    }
}

// MARK: - Preview

#Preview("Race Card Variants") {
    ScrollView {
        VStack(spacing: 20) {
            // Featured card
            Text("Featured")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            RaceCardView(
                race: .preview,
                style: .featured,
                isNext: true
            )
            
            // Standard cards
            Text("Standard")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            RaceCardView(
                race: .preview,
                style: .standard,
                isNext: true
            )
            
            RaceCardView(
                race: Race(
                    season: "2024",
                    round: "2",
                    raceName: "Saudi Arabian Grand Prix",
                    circuit: Circuit(
                        circuitId: "jeddah",
                        circuitName: "Jeddah Corniche Circuit",
                        location: CircuitLocation(locality: "Jeddah", country: "Saudi Arabia")
                    ),
                    date: "2024-03-09",
                    time: "17:00:00Z",
                    firstPractice: nil,
                    secondPractice: nil,
                    thirdPractice: nil,
                    qualifying: nil,
                    sprint: nil
                ),
                style: .standard
            )
            
            // Compact cards
            Text("Compact")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            RaceCardView(
                race: .preview,
                style: .compact
            )
            
            RaceCardView(
                race: Race(
                    season: "2024",
                    round: "3",
                    raceName: "Australian Grand Prix",
                    circuit: Circuit(
                        circuitId: "albert_park",
                        circuitName: "Albert Park Circuit",
                        location: CircuitLocation(locality: "Melbourne", country: "Australia")
                    ),
                    date: "2024-03-24",
                    time: "04:00:00Z",
                    firstPractice: nil,
                    secondPractice: nil,
                    thirdPractice: nil,
                    qualifying: nil,
                    sprint: nil
                ),
                style: .compact
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
