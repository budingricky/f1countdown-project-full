//
//  RaceListView.swift
//  F1Countdown
//
//  Main view displaying the race schedule with grouping, search, and filtering
//

import SwiftUI

// MARK: - Race List View

/// Main view displaying F1 race schedule
struct RaceListView: View {
    // MARK: - Environment
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - View Model
    
    @StateObject private var viewModel: RaceListViewModel
    
    // MARK: - Selection State
    
    /// Selected race for navigation (iPad)
    @State private var selectedRace: Race?
    
    /// Search focus state
    @FocusState private var isSearchFocused: Bool
    
    // MARK: - Initialization
    
    init(viewModel: RaceListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            if horizontalSizeClass == .regular && geometry.size.width > 600 {
                // iPad: Split view
                NavigationSplitView {
                    listContent
                        .navigationTitle("F1 Countdown")
                        .navigationBarTitleDisplayMode(.large)
                } detail: {
                    if let race = selectedRace {
                        RaceDetailView(race: race)
                    } else {
                        emptySelectionView
                    }
                }
            } else {
                // iPhone: Navigation stack
                NavigationStack {
                    listContent
                        .navigationTitle("F1 Countdown")
                        .navigationBarTitleDisplayMode(.large)
                }
            }
        }
    }
    
    // MARK: - List Content
    
    @ViewBuilder
    private var listContent: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                    // Featured next race
                    if let nextRace = viewModel.nextRace {
                        featuredSection(nextRace)
                    }
                    
                    // Filter chips
                    filterSection
                    
                    // Race list by section
                    if viewModel.isLoading && viewModel.races.isEmpty {
                        loadingView
                    } else if viewModel.filteredRaces.isEmpty {
                        emptyView
                    } else {
                        raceSections
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refreshFromPullToRefresh()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                settingsButton
            }
            
            ToolbarItem(placement: .automatic) {
                seasonPicker
            }
        }
        .searchable(
            text: $viewModel.searchQuery,
            isPresented: $isSearchFocused,
            placement: .automatic,
            prompt: "Search races, circuits..."
        )
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await viewModel.refresh() }
            }
        }
    }
    
    // MARK: - Section Views
    
    @ViewBuilder
    private func featuredSection(_ race: Race) -> some View {
        Section {
            NavigationLink(value: race) {
                RaceCardView(
                    race: race,
                    style: .featured,
                    isNext: true
                ) { tappedRace in
                    selectedRace = tappedRace
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RaceFilterMode.allCases, id: \.self) { mode in
                    FilterChip(
                        title: mode.displayName,
                        icon: mode.icon,
                        isSelected: viewModel.filterMode == mode
                    ) {
                        viewModel.setFilterMode(mode)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var raceSections: some View {
        // Upcoming races
        if !viewModel.upcomingRaces.isEmpty {
            Section {
                ForEach(viewModel.upcomingRaces) { race in
                    NavigationLink(value: race) {
                        RaceCardView(
                            race: race,
                            style: .standard,
                            isNext: race.id == viewModel.nextRace?.id
                        ) { tappedRace in
                            selectedRace = tappedRace
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                SectionHeader(
                    title: "Upcoming",
                    count: viewModel.upcomingRaces.count,
                    icon: "clock"
                )
            }
        }
        
        // Completed races
        if !viewModel.completedRaces.isEmpty {
            Section {
                ForEach(viewModel.completedRaces) { race in
                    NavigationLink(value: race) {
                        RaceCardView(
                            race: race,
                            style: .standard
                        ) { tappedRace in
                            selectedRace = tappedRace
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                SectionHeader(
                    title: "Completed",
                    count: viewModel.completedRaces.count,
                    icon: "checkered.flag"
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading race calendar...")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No races found")
                .font(.system(.headline, design: .rounded))
            
            if !viewModel.searchQuery.isEmpty {
                Text("Try adjusting your search or filters")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            } else {
                Text("Pull down to refresh")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    @ViewBuilder
    private var emptySelectionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary)
            
            Text("Select a race")
                .font(.system(.title2, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    @ViewBuilder
    private var settingsButton: some View {
        NavigationLink {
            SettingsView()
        } label: {
            Image(systemName: "gearshape")
                .font(.system(.body, design: .rounded))
        }
    }
    
    @ViewBuilder
    private var seasonPicker: some View {
        Menu {
            ForEach(viewModel.availableSeasons, id: \.self) { year in
                Button {
                    viewModel.selectSeason(year)
                } label: {
                    HStack {
                        Text(String(year))
                        if viewModel.selectedSeason == year {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(String(viewModel.selectedSeason ?? viewModel.currentSeason))
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.system(.caption2))
            }
            .foregroundColor(.primary)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(.caption2))
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(red: 0.9, green: 0.1, blue: 0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let count: Int
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
            
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.primary)
            
            Text("(\(count))")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("Race List - iPhone") {
    NavigationStack {
        RaceListView(viewModel: .preview)
    }
}

#Preview("Race List - iPad") {
    RaceListView(viewModel: .preview)
        .previewInterfaceOrientation(.landscapeLeft)
}
