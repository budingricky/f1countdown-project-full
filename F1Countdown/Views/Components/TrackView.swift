//
//  TrackView.swift
//  F1Countdown
//
//  Base SwiftUI track visualization component
//

import SwiftUI

/// A SwiftUI view that renders an F1 circuit track
struct TrackView: View {
    // MARK: - Properties
    
    let track: TrackData
    
    /// Whether to show track details overlay
    var showDetails: Bool = true
    
    /// Custom stroke width for the track outline
    var strokeWidth: CGFloat = 4
    
    /// Whether the track is selected (affects appearance)
    var isSelected: Bool = false
    
    /// Animation state for pulsing effect
    @State private var isPulsing: Bool = false
    
    /// Tap action callback
    var onTap: ((TrackData) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background glow
                trackBackground(in: geometry.size)
                
                // Track shape
                trackShape(in: geometry.size)
                
                // Track details overlay
                if showDetails {
                    trackDetailsOverlay(in: geometry.size)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?(track)
                withAnimation(.easeInOut(duration: 0.15)) {
                    isPulsing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPulsing = false
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func trackBackground(in size: CGSize) -> some View {
        CircuitShape(circuitId: track.circuitId)
            .fill(track.primaryColor.opacity(0.15))
            .blur(radius: 20)
            .scaleEffect(isPulsing ? 1.05 : 1.0)
    }
    
    @ViewBuilder
    private func trackShape(in size: CGSize) -> some View {
        ZStack {
            // Outer glow
            CircuitShape(circuitId: track.circuitId)
                .stroke(
                    track.primaryColor.opacity(0.5),
                    lineWidth: strokeWidth + 8
                )
                .blur(radius: 8)
            
            // Main track outline
            CircuitShape(circuitId: track.circuitId)
                .stroke(
                    LinearGradient(
                        colors: [
                            track.primaryColor,
                            track.secondaryColor.opacity(0.8),
                            track.primaryColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: strokeWidth
                )
            
            // Inner highlight
            CircuitShape(circuitId: track.circuitId)
                .stroke(
                    Color.white.opacity(0.3),
                    lineWidth: 1
                )
                .offset(x: 0.5, y: 0.5)
        }
        .scaleEffect(isPulsing ? 1.02 : 1.0)
    }
    
    @ViewBuilder
    private func trackDetailsOverlay(in size: CGSize) -> some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(track.countryFlag)
                            .font(.system(size: 14))
                        Text(track.circuitName)
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Text(track.locality)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(track.turnCount) turns")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.3f km", track.trackLength))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .padding(8)
        }
    }
}

// MARK: - Preview

#Preview("Track Views") {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(TrackData.allTracks) { track in
                TrackView(track: track)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Single Track") {
    TrackView(track: .monaco)
        .frame(height: 300)
        .padding()
        .background(Color(.systemBackground))
}
