//
//  LiquidGlassTrackView.swift
//  F1Countdown
//
//  Track visualization with liquid glass effect (iOS 26+) and fallback design
//

import SwiftUI

/// A track view with liquid glass effect for iOS 26+ and elegant fallback for earlier versions
struct LiquidGlassTrackView: View {
    // MARK: - Properties
    
    let track: TrackData
    
    /// Whether to show track details overlay
    var showDetails: Bool = true
    
    /// Whether the track is highlighted/selected
    var isHighlighted: Bool = false
    
    /// Animation phase for shimmer effect
    @State private var shimmerPhase: CGFloat = 0
    
    /// Animation phase for glow pulse
    @State private var glowPhase: CGFloat = 0
    
    /// Tap action callback
    var onTap: ((TrackData) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background atmosphere
                backgroundLayer(in: geometry.size)
                
                // Glass track container
                glassTrackContainer(in: geometry.size)
                
                // Track details overlay
                if showDetails {
                    detailsOverlay(in: geometry.size)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?(track)
                triggerHapticFeedback()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimations() {
        // Shimmer animation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            shimmerPhase = 1
        }
        
        // Glow pulse animation
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPhase = 1
        }
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func backgroundLayer(in size: CGSize) -> some View {
        // Animated gradient background
        ZStack {
            // Base color
            track.primaryColor
                .opacity(0.08)
            
            // Animated glow spots
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                track.primaryColor.opacity(0.3),
                                track.primaryColor.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.4
                        )
                    )
                    .frame(width: size.width * 0.6, height: size.width * 0.6)
                    .offset(
                        x: CGFloat(cos(Double(glowPhase + CGFloat(index)) * .pi * 2)) * size.width * 0.2,
                        y: CGFloat(sin(Double(glowPhase + CGFloat(index)) * .pi * 2)) * size.height * 0.15
                    )
                    .blur(radius: 20)
            }
        }
    }
    
    @ViewBuilder
    private func glassTrackContainer(in size: CGSize) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26+ Liquid Glass Effect
            liquidGlassTrack(in: size)
        } else {
            // Fallback: Elegant glass simulation
            fallbackGlassTrack(in: size)
        }
    }
    
    // MARK: - iOS 26+ Liquid Glass
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private func liquidGlassTrack(in size: CGSize) -> some View {
        ZStack {
            // Glass container with native glass effect
            CircuitShape(circuitId: track.circuitId)
                .fill(.white.opacity(0.1))
                .glassEffect()
            
            // Track outline with glass
            CircuitShape(circuitId: track.circuitId)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.8),
                            .white.opacity(0.3),
                            .white.opacity(0.6)
                        ],
                        startPoint: UnitPoint(x: shimmerPhase, y: 0),
                        endPoint: UnitPoint(x: 1 - shimmerPhase, y: 1)
                    ),
                    lineWidth: 3
                )
                .glassEffect()
            
            // Colored highlight
            CircuitShape(circuitId: track.circuitId)
                .stroke(
                    track.primaryColor.opacity(0.6),
                    lineWidth: 1.5
                )
        }
        .shadow(
            color: track.primaryColor.opacity(0.3),
            radius: isHighlighted ? 20 : 10
        )
        .scaleEffect(isHighlighted ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
    }
    
    // MARK: - Fallback Glass Effect (iOS < 26)
    
    @ViewBuilder
    private func fallbackGlassTrack(in size: CGSize) -> some View {
        ZStack {
            // Glass layer - base
            CircuitShape(circuitId: track.circuitId)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Inner glass highlight
            CircuitShape(circuitId: track.circuitId)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .blur(radius: 2)
            
            // Glass border - outer
            CircuitShape(circuitId: track.circuitId)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.4)
                        ],
                        startPoint: UnitPoint(x: shimmerPhase, y: 0),
                        endPoint: UnitPoint(x: 1 - shimmerPhase, y: 1)
                    ),
                    lineWidth: 2
                )
            
            // Colored track outline
            CircuitShape(circuitId: track.circuitId)
                .stroke(
                    LinearGradient(
                        colors: [
                            track.primaryColor,
                            track.secondaryColor,
                            track.primaryColor
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
                .blur(radius: 0.5)
            
            // Shimmer effect
            CircuitShape(circuitId: track.circuitId)
                .stroke(
                    Color.white.opacity(0.5),
                    lineWidth: 1
                )
                .mask(
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.8),
                            .clear
                        ],
                        startPoint: UnitPoint(x: -0.5 + shimmerPhase * 2, y: 0),
                        endPoint: UnitPoint(x: 0.5 + shimmerPhase * 2, y: 1)
                    )
                )
        }
        .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: 4)
        .shadow(color: track.primaryColor.opacity(0.3), radius: isHighlighted ? 15 : 8)
        .scaleEffect(isHighlighted ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
    }
    
    // MARK: - Details Overlay
    
    @ViewBuilder
    private func detailsOverlay(in size: CGSize) -> some View {
        VStack {
            Spacer()
            
            HStack(alignment: .bottom) {
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(track.countryFlag)
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(track.circuitName)
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(track.locality + ", " + track.country)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.system(.caption2))
                            .foregroundColor(track.primaryColor)
                        Text("\(track.turnCount)")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    
                    if let lapRecord = track.lapRecord {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(.caption2))
                                .foregroundColor(track.primaryColor)
                            Text(lapRecord)
                                .font(.system(.caption2, design: .monospaced))
                        }
                    }
                    
                    Text(String(format: "%.3f km", track.trackLength))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .glassEffect()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(10)
        }
    }
}

// MARK: - Track Card Style

extension LiquidGlassTrackView {
    /// Apply card styling with rounded corners
    func cardStyle() -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

// MARK: - Preview

#Preview("Liquid Glass Tracks - Grid") {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(TrackData.allTracks) { track in
                LiquidGlassTrackView(track: track)
                    .frame(height: 200)
                    .cardStyle()
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Liquid Glass - Single Track") {
    VStack(spacing: 20) {
        LiquidGlassTrackView(track: .monaco, isHighlighted: true)
            .frame(height: 280)
            .cardStyle()
        
        LiquidGlassTrackView(track: .suzuka)
            .frame(height: 200)
            .cardStyle()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Track Selection State") {
    @Previewable @State var selectedTrack: TrackData? = nil
    
    ScrollView {
        LazyVStack(spacing: 16) {
            ForEach(TrackData.allTracks) { track in
                LiquidGlassTrackView(
                    track: track,
                    isHighlighted: selectedTrack?.id == track.id
                ) { tapped in
                    selectedTrack = tapped
                }
                .frame(height: 140)
                .cardStyle()
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
