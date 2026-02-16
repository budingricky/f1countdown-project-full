//
//  ProBadgeView.swift
//  F1Countdown
//
//  Pro feature badge component with premium styling
//

import SwiftUI

// MARK: - Pro Badge View

/// A premium badge indicating Pro features
struct ProBadgeView: View {
    // MARK: - Properties
    
    /// Badge style variant
    var style: BadgeStyle = .standard
    
    /// Whether to show the badge as locked
    var isLocked: Bool = false
    
    /// Animation state for shimmer effect
    @State private var shimmerPhase: CGFloat = 0
    
    // MARK: - Badge Style
    
    enum BadgeStyle {
        case standard
        case compact
        case large
        case banner
        
        var height: CGFloat {
            switch self {
            case .standard: return 24
            case .compact: return 18
            case .large: return 32
            case .banner: return 36
            }
        }
        
        var fontSize: Font {
            switch self {
            case .standard: return .system(.caption, design: .rounded)
            case .compact: return .system(.caption2, design: .rounded)
            case .large: return .system(.subheadline, design: .rounded)
            case .banner: return .system(.body, design: .rounded)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isLocked {
                lockedBadge
            } else {
                proBadge
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var proBadge: some View {
        HStack(spacing: style == .compact ? 3 : 5) {
            // Pro icon
            if style != .compact {
                Image(systemName: "crown.fill")
                    .font(style == .large ? .system(.caption) : .system(.caption2))
            }
            
            Text("PRO")
                .font(fontSize)
                .fontWeight(.heavy)
                .tracking(0.5)
        }
        .foregroundStyle(
            LinearGradient(
                colors: [
                    .white,
                    Color(red: 1.0, green: 0.95, blue: 0.8),
                    .white
                ],
                startPoint: UnitPoint(x: shimmerPhase, y: 0),
                endPoint: UnitPoint(x: shimmerPhase + 0.5, y: 1)
            )
        )
        .padding(.horizontal, style == .compact ? 6 : 10)
        .padding(.vertical, style == .compact ? 3 : 5)
        .background(
            GeometryReader { geometry in
                // Premium gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.6, green: 0.3, blue: 0.8),  // Purple
                        Color(red: 0.9, green: 0.4, blue: 0.6),  // Pink
                        Color(red: 1.0, green: 0.6, blue: 0.2),  // Orange/Gold
                        Color(red: 0.9, green: 0.4, blue: 0.6),  // Pink
                        Color(red: 0.6, green: 0.3, blue: 0.8)   // Purple
                    ],
                    startPoint: UnitPoint(x: shimmerPhase * 0.5, y: 0),
                    endPoint: UnitPoint(x: shimmerPhase * 0.5 + 1, y: 1)
                )
                .clipShape(Capsule())
                
                // Shimmer overlay
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: UnitPoint(x: -0.5 + shimmerPhase * 1.5, y: 0),
                            endPoint: UnitPoint(x: 0 + shimmerPhase * 1.5, y: 1)
                        )
                    )
            }
        )
        .clipShape(Capsule())
        .shadow(color: Color(red: 0.6, green: 0.3, blue: 0.8).opacity(0.4), radius: 4, x: 0, y: 2)
        .accessibilityLabel("Pro feature")
    }
    
    @ViewBuilder
    private var lockedBadge: some View {
        HStack(spacing: style == .compact ? 3 : 5) {
            Image(systemName: "lock.fill")
                .font(style == .compact ? .system(.caption2) : .system(.caption))
            
            Text("PRO")
                .font(fontSize)
                .fontWeight(.heavy)
                .tracking(0.5)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, style == .compact ? 6 : 10)
        .padding(.vertical, style == .compact ? 3 : 5)
        .background(
            Capsule()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemBackground))
                )
        )
        .accessibilityLabel("Pro feature locked")
    }
}

// MARK: - Pro Feature Container

/// A container that shows Pro badge and locks content if not Pro
struct ProFeatureView<Content: View>: View {
    var isPro: Bool
    var onUnlock: (() -> Void)?
    @ViewBuilder let content: () -> Content
    
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            content()
            
            if !isPro {
                // Dimming overlay
                Color.black.opacity(0.4)
                    .blur(radius: 2)
                
                // Lock overlay
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "lock.fill")
                            .font(.system(.title2))
                            .foregroundColor(.white)
                    }
                    
                    Text("Pro Feature")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                    
                    Button {
                        onUnlock?()
                    } label: {
                        Text("Unlock")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.6, green: 0.3, blue: 0.8),
                                                Color(red: 0.9, green: 0.4, blue: 0.6)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onUnlock?()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview("Pro Badge Variants") {
    VStack(spacing: 24) {
        // Standard
        HStack {
            Text("Standard:")
            ProBadgeView(style: .standard)
        }
        
        // Compact
        HStack {
            Text("Compact:")
            ProBadgeView(style: .compact)
        }
        
        // Large
        HStack {
            Text("Large:")
            ProBadgeView(style: .large)
        }
        
        // Banner
        HStack {
            Text("Banner:")
            ProBadgeView(style: .banner)
        }
        
        Divider()
        
        // Locked variants
        HStack {
            Text("Locked:")
            ProBadgeView(style: .standard, isLocked: true)
        }
        
        HStack {
            Text("Locked Compact:")
            ProBadgeView(style: .compact, isLocked: true)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Pro Feature View") {
    VStack(spacing: 20) {
        // Unlocked
        ProFeatureView(isPro: true) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.gradient)
                .frame(height: 100)
                .overlay(
                    Text("Premium Content")
                        .foregroundColor(.white)
                )
        }
        
        // Locked
        ProFeatureView(isPro: false) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.gradient)
                .frame(height: 100)
                .overlay(
                    Text("Premium Content")
                        .foregroundColor(.white)
                )
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
