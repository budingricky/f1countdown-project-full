//
//  CountdownView.swift
//  F1Countdown
//
//  Real-time countdown display component with F1-inspired design
//

import SwiftUI

// MARK: - Countdown Unit

/// A single countdown digit/unit display with animation
struct CountdownUnit: View {
    let value: Int
    let label: String
    let accentColor: Color
    
    @State private var previousValue: Int?
    @State private var isFlipping = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Value display
            ZStack {
                // Background card
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemBackground).opacity(0.9),
                                Color(.systemBackground).opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Value text
                Text(String(format: "%02d", value))
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.heavy)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
            }
            .frame(minWidth: 44, minHeight: 52)
            .scaleEffect(isFlipping ? 0.95 : 1.0)
            
            // Label
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .onChange(of: value) { oldValue, newValue in
            if oldValue != newValue {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                    isFlipping = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                        isFlipping = false
                    }
                }
            }
        }
    }
}

// MARK: - Countdown View

/// Real-time countdown display with F1-inspired aesthetic
struct CountdownView: View {
    // MARK: - Properties
    
    /// Target date for the countdown
    let targetDate: Date
    
    /// Accent color for the countdown (defaults to F1 red)
    var accentColor: Color = Color(red: 0.9, green: 0.1, blue: 0.1)
    
    /// Whether to show a compact style
    var isCompact: Bool = false
    
    /// Whether the countdown is live (race in progress)
    var isLive: Bool = false
    
    /// Countdown state
    @State private var remainingTime: TimeInterval = 0
    @State private var timer: Timer?
    
    // MARK: - Computed Properties
    
    private var days: Int {
        max(0, Int(remainingTime) / 86400)
    }
    
    private var hours: Int {
        max(0, (Int(remainingTime) % 86400) / 3600)
    }
    
    private var minutes: Int {
        max(0, (Int(remainingTime) % 3600) / 60)
    }
    
    private var seconds: Int {
        max(0, Int(remainingTime) % 60)
    }
    
    private var isFinished: Bool {
        remainingTime <= 0
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isCompact {
                compactView
            } else {
                fullView
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - View Variants
    
    @ViewBuilder
    private var fullView: some View {
        VStack(spacing: 16) {
            // Header
            if isLive {
                liveIndicator
            } else if isFinished {
                finishedIndicator
            } else {
                countdownHeader
            }
            
            // Countdown display
            if !isFinished {
                HStack(spacing: isCompact ? 6 : 12) {
                    if days > 0 {
                        CountdownUnit(value: days, label: "Days", accentColor: accentColor)
                        separator
                    }
                    
                    CountdownUnit(value: hours, label: "Hours", accentColor: accentColor)
                    separator
                    
                    CountdownUnit(value: minutes, label: "Min", accentColor: accentColor)
                    separator
                    
                    CountdownUnit(value: seconds, label: "Sec", accentColor: accentColor)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Countdown: \(days) days, \(hours) hours, \(minutes) minutes, \(seconds) seconds")
            }
        }
    }
    
    @ViewBuilder
    private var compactView: some View {
        HStack(spacing: 4) {
            if isLive {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 4)
                            .scaleEffect(1.5)
                    )
                
                Text("LIVE")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            } else if isFinished {
                Text("FINISHED")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            } else {
                if days > 0 {
                    Text("\(days)d")
                        .foregroundColor(accentColor)
                }
                Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .accessibilityLabel(remainingTime > 0 ? "Countdown: \(days) days, \(hours) hours, \(minutes) minutes, \(seconds) seconds remaining" : "Event finished")
    }
    
    @ViewBuilder
    private var separator: some View {
        Text(":")
            .font(.system(.title, design: .monospaced))
            .fontWeight(.heavy)
            .foregroundColor(accentColor.opacity(0.6))
    }
    
    @ViewBuilder
    private var countdownHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(accentColor)
            
            Text("LIGHTS OUT IN")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(1)
        }
    }
    
    @ViewBuilder
    private var liveIndicator: some View {
        HStack(spacing: 10) {
            // Pulsing live indicator
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 6)
                        .scaleEffect(1.5)
                )
                .symbolEffect(.pulse, options: .repeating, isActive: true)
            
            Text("RACE IN PROGRESS")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.green)
                .tracking(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.15))
        )
    }
    
    @ViewBuilder
    private var finishedIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkered.flag")
                .font(.system(.title, design: .rounded))
                .foregroundColor(accentColor)
            
            Text("RACE FINISHED")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(1)
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        updateRemainingTime()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateRemainingTime()
        }
        
        // Common/RunLoop optimization
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateRemainingTime() {
        remainingTime = max(0, targetDate.timeIntervalSinceNow)
        
        // Stop timer when countdown finishes
        if remainingTime <= 0 {
            stopTimer()
        }
    }
}

// MARK: - Preview

#Preview("Countdown - Full") {
    VStack(spacing: 40) {
        // Future event
        CountdownView(
            targetDate: Date().addingTimeInterval(86400 * 3 + 3600 * 5 + 1800),
            accentColor: Color(red: 0.9, green: 0.1, blue: 0.1)
        )
        
        // Less than a day
        CountdownView(
            targetDate: Date().addingTimeInterval(3600 * 5 + 1800),
            accentColor: Color(red: 0.0, green: 0.3, blue: 0.7)
        )
        
        // Live indicator
        CountdownView(
            targetDate: Date().addingTimeInterval(-300),
            isLive: true
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Countdown - Compact") {
    VStack(spacing: 20) {
        // Future
        CountdownView(
            targetDate: Date().addingTimeInterval(86400 * 3 + 3600 * 5 + 1800),
            isCompact: true
        )
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        
        // Live
        CountdownView(
            targetDate: Date().addingTimeInterval(-300),
            isCompact: true,
            isLive: true
        )
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        
        // Finished
        CountdownView(
            targetDate: Date().addingTimeInterval(-3600),
            isCompact: true
        )
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
