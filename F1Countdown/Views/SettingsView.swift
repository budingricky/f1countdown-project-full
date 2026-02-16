//
//  SettingsView.swift
//  F1Countdown
//
//  Settings page with notification preferences and Pro upgrade
//

import SwiftUI

// MARK: - Settings View

/// Settings page for the F1 Countdown app
struct SettingsView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    // MARK: - State
    
    @StateObject private var preferences = PreferencesManager.shared
    @State private var showProSheet = false
    @State private var showAboutSheet = false
    
    // MARK: - Pro Status (would be connected to StoreKit in production)
    @State private var isProUser: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            // Pro Section
            proSection
            
            // Notifications Section
            notificationsSection
            
            // Display Section
            displaySection
            
            // About Section
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProSheet) {
            ProUpgradeSheet(isProUser: $isProUser)
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutSheet()
        }
    }
    
    // MARK: - Pro Section
    
    @ViewBuilder
    private var proSection: some View {
        Section {
            Button {
                showProSheet = true
            } label: {
                HStack(spacing: 16) {
                    // Pro icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.3, blue: 0.8),
                                        Color(red: 0.9, green: 0.4, blue: 0.6),
                                        Color(red: 1.0, green: 0.6, blue: 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(.title3))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("F1 Countdown Pro")
                                .font(.system(.headline, design: .rounded))
                            
                            if isProUser {
                                ProBadgeView(style: .compact)
                            }
                        }
                        
                        Text(isProUser ? "All features unlocked" : "Unlock premium features")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(.caption))
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Text("Premium")
        } footer: {
            if !isProUser {
                Text("Get live activities, advanced notifications, and more.")
            }
        }
    }
    
    // MARK: - Notifications Section
    
    @ViewBuilder
    private var notificationsSection: some View {
        Section {
            // Master toggle
            Toggle(isOn: Binding(
                get: { preferences.preferences.notificationsEnabled },
                set: { _ in preferences.toggleNotifications() }
            )) {
                Label {
                    Text("Notifications")
                        .font(.system(.subheadline, design: .rounded))
                } icon: {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                }
            }
            .tint(Color(red: 0.9, green: 0.1, blue: 0.1))
            
            if preferences.preferences.notificationsEnabled {
                // Notification timing
                NavigationLink {
                    NotificationTimingView(
                        selectedTimings: preferences.preferences.notificationTimingEnums
                    ) { timings in
                        preferences.updateNotificationTimings(timings)
                    }
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notification Timing")
                                .font(.system(.subheadline, design: .rounded))
                            
                            Text(notificationTimingSummary)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                // Session types
                NavigationLink {
                    SessionTypesView(
                        selectedTypes: preferences.preferences.sessionNotificationTypeEnums
                    ) { types in
                        preferences.updateSessionTypes(types)
                    }
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Session Types")
                                .font(.system(.subheadline, design: .rounded))
                            
                            Text(sessionTypesSummary)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "flag.checkered")
                            .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
                    }
                }
                
                // Sound
                Toggle(isOn: Binding(
                    get: { preferences.preferences.soundEnabled },
                    set: { _ in
                        preferences.preferences.soundEnabled = $0
                        preferences.save()
                    }
                )) {
                    Label {
                        Text("Sound")
                            .font(.system(.subheadline, design: .rounded))
                    } icon: {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.green)
                    }
                }
                .tint(Color(red: 0.9, green: 0.1, blue: 0.1))
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Receive reminders before race sessions start.")
        }
    }
    
    // MARK: - Display Section
    
    @ViewBuilder
    private var displaySection: some View {
        Section {
            // Theme picker
            Picker(selection: Binding(
                get: { preferences.preferences.themeEnum },
                set: { preferences.updateTheme($0) }
            )) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName)
                        .tag(theme)
                }
            } label: {
                Label {
                    Text("Theme")
                        .font(.system(.subheadline, design: .rounded))
                } icon: {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.purple)
                }
            }
            
            // Show completed races
            Toggle(isOn: Binding(
                get: { preferences.preferences.showCompletedRaces },
                set: { _ in preferences.toggleShowCompletedRaces() }
            )) {
                Label {
                    Text("Show Completed Races")
                        .font(.system(.subheadline, design: .rounded))
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .tint(Color(red: 0.9, green: 0.1, blue: 0.1))
            
            // Time zone mode
            Picker(selection: Binding(
                get: { preferences.preferences.timeZoneMode },
                set: {
                    preferences.preferences.timeZoneMode = $0
                    preferences.save()
                }
            )) {
                Text("Local Time").tag("local")
                Text("Circuit Time").tag("circuit")
            } label: {
                Label {
                    Text("Time Display")
                        .font(.system(.subheadline, design: .rounded))
                } icon: {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                }
            }
        } header: {
            Text("Display")
        }
    }
    
    // MARK: - About Section
    
    @ViewBuilder
    private var aboutSection: some View {
        Section {
            Button {
                showAboutSheet = true
            } label: {
                Label {
                    Text("About F1 Countdown")
                        .font(.system(.subheadline, design: .rounded))
                } icon: {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            Link(destination: URL(string: "https://formula1.com")!) {
                Label {
                    Text("Official F1 Website")
                        .font(.system(.subheadline, design: .rounded))
                } icon: {
                    Image(systemName: "safari.fill")
                        .foregroundColor(.orange)
                }
            }
            
            Button {
                if let url = URL(string: "mailto:feedback@f1countdown.app") {
                    openURL(url)
                }
            } label: {
                Label {
                    Text("Send Feedback")
                        .font(.system(.subheadline, design: .rounded))
                } icon: {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                Label {
                    Text("Version")
                        .font(.system(.subheadline, design: .rounded))
                } icon: {
                    Image(systemName: "number.circle.fill")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("1.0.0")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("About")
        }
    }
    
    // MARK: - Helpers
    
    private var notificationTimingSummary: String {
        let timings = preferences.preferences.notificationTimingEnums
        if timings.isEmpty { return "None selected" }
        return timings.map { $0.displayName }.joined(separator: ", ")
    }
    
    private var sessionTypesSummary: String {
        let types = preferences.preferences.sessionNotificationTypeEnums
        if types.isEmpty { return "None selected" }
        return types.map { $0.displayName }.joined(separator: ", ")
    }
}

// MARK: - Notification Timing View

struct NotificationTimingView: View {
    let selectedTimings: [NotificationTiming]
    let onSave: ([NotificationTiming]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var timings: Set<NotificationTiming> = []
    
    var body: some View {
        List {
            ForEach(NotificationTiming.allCases, id: \.self) { timing in
                Button {
                    if timings.contains(timing) {
                        timings.remove(timing)
                    } else {
                        timings.insert(timing)
                    }
                } label: {
                    HStack {
                        Text(timing.displayName)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if timings.contains(timing) {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
                        }
                    }
                }
            }
        }
        .navigationTitle("Notification Timing")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            timings = Set(selectedTimings)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(Array(timings))
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Session Types View

struct SessionTypesView: View {
    let selectedTypes: [SessionNotificationType]
    let onSave: ([SessionNotificationType]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var types: Set<SessionNotificationType> = []
    
    var body: some View {
        List {
            ForEach(SessionNotificationType.allCases, id: \.self) { type in
                Button {
                    if types.contains(type) {
                        types.remove(type)
                    } else {
                        types.insert(type)
                    }
                } label: {
                    HStack {
                        Text(type.displayName)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if types.contains(type) {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
                        }
                    }
                }
            }
        }
        .navigationTitle("Session Types")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            types = Set(selectedTypes)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(Array(types))
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Pro Upgrade Sheet

struct ProUpgradeSheet: View {
    @Binding var isProUser: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.6, green: 0.3, blue: 0.8),
                                            Color(red: 0.9, green: 0.4, blue: 0.6),
                                            Color(red: 1.0, green: 0.6, blue: 0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(.largeTitle))
                                .foregroundColor(.white)
                        }
                        
                        Text("F1 Countdown Pro")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.heavy)
                        
                        Text("Unlock the ultimate F1 experience")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Features
                    VStack(spacing: 16) {
                        ProFeatureRow(
                            icon: "bell.badge.fill",
                            title: "Advanced Notifications",
                            description: "Custom reminders for every session"
                        )
                        
                        ProFeatureRow(
                            icon: "waveform.path",
                            title: "Live Activities",
                            description: "Real-time race updates on your lock screen"
                        )
                        
                        ProFeatureRow(
                            icon: "rectangle.topright.inset.filled",
                            title: "Home Screen Widgets",
                            description: "Beautiful countdown widgets in all sizes"
                        )
                        
                        ProFeatureRow(
                            icon: "heart.fill",
                            title: "Support Development",
                            description: "Help us build more great features"
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Price
                    VStack(spacing: 8) {
                        Text("¥18")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.heavy)
                        
                        Text("One-time purchase")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical)
                    
                    // CTA Button
                    Button {
                        // In production, this would trigger StoreKit purchase
                        isProUser = true
                        dismiss()
                    } label: {
                        Text("Unlock Pro")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.3, blue: 0.8),
                                        Color(red: 0.9, green: 0.4, blue: 0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Restore button
                    Button {
                        // In production, this would restore purchases
                    } label: {
                        Text("Restore Purchases")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Pro Feature Row

struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(.title3))
                .foregroundColor(Color(red: 0.6, green: 0.3, blue: 0.8))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - About Sheet

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.9, green: 0.1, blue: 0.1),
                                        Color(red: 0.7, green: 0.0, blue: 0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "flag.checkered")
                            .font(.system(.largeTitle))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("F1 Countdown")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.heavy)
                        
                        Text("Version 1.0.0")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Never miss the lights out again. F1 Countdown brings you real-time race countdowns, beautiful track visualizations, and smart notifications for every session of the Formula 1 season.")
                        .font(.system(.body, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 32)
                    
                    Divider()
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 16) {
                        Text("Data provided by")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Text("Jolpica-F1 API")
                            .font(.system(.headline, design: .rounded))
                        
                        Text("Made with ❤️ for F1 fans")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("© 2024 F1 Countdown. Formula 1 is a registered trademark of Formula One Licensing BV.")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
}

#Preview("Pro Sheet") {
    ProUpgradeSheet(isProUser: .constant(false))
}

#Preview("About Sheet") {
    AboutSheet()
}
