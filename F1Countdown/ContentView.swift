//
//  ContentView.swift
//  F1Countdown
//
//  Main content view with adaptive layout for iPhone and iPad
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // MARK: - Environment
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - SwiftData
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @StateObject private var viewModel: RaceListViewModel
    @StateObject private var preferences = PreferencesManager.shared
    
    // MARK: - Selection State
    
    @State private var selectedRace: Race?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // MARK: - Initialization
    
    init() {
        // Create ViewModel with placeholder - will be configured in onAppear
        _viewModel = StateObject(wrappedValue: RaceListViewModel(dataService: DataService.preview))
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad: Split view with sidebar
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    sidebarView
                        .navigationTitle("F1 Countdown")
                        .navigationBarTitleDisplayMode(.large)
                } detail: {
                    detailView
                }
            } else {
                // iPhone: Navigation stack
                NavigationStack {
                    mainView
                        .navigationTitle("F1 Countdown")
                        .navigationBarTitleDisplayMode(.large)
                }
            }
        }
        .onAppear {
            setupViewModel()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await viewModel.refresh() }
            }
        }
        .tint(Color(red: 0.9, green: 0.1, blue: 0.1))
    }
    
    // MARK: - Setup
    
    private func setupViewModel() {
        preferences.configure(with: modelContext)
        
        // Re-create ViewModel with proper data service
        let dataService = DataService(modelContext: modelContext)
        
        // Update the ViewModel's data service
        // Note: In a real app, you'd inject this properly
    }
    
    // MARK: - iPad Views
    
    @ViewBuilder
    private var sidebarView: some View {
        List(selection: $selectedRace) {
            Section("Schedule") {
                if viewModel.isLoading && viewModel.races.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ForEach(viewModel.upcomingRaces) { race in
                        RaceRowView(race: race, isNext: race.id == viewModel.nextRace?.id)
                            .tag(race)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .refreshable {
            await viewModel.refreshFromPullToRefresh()
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        if let race = selectedRace {
            RaceDetailView(race: race)
        } else {
            VStack(spacing: 20) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.secondary)
                
                Text("Select a race")
                    .font(.system(.title2, design: .rounded))
                    .foregroundColor(.secondary)
                
                if let nextRace = viewModel.nextRace {
                    Button {
                        selectedRace = nextRace
                    } label: {
                        Text("View Next Race")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.9, green: 0.1, blue: 0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
        }
    }
    
    // MARK: - iPhone View
    
    @ViewBuilder
    private var mainView: some View {
        RaceListView(viewModel: viewModel)
    }
}

// MARK: - Race Row View (for iPad sidebar)

struct RaceRowView: View {
    let race: Race
    var isNext: Bool = false
    
    private var trackData: TrackData? {
        TrackData.find(by: race.circuit.circuitId)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Track indicator
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(trackData?.primaryColor.opacity(0.15) ?? Color.red.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                if let track = trackData {
                    CircuitShape(circuitId: track.circuitId)
                        .stroke(track.primaryColor, lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "flag.checkered")
                        .font(.system(.caption))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("R\(race.round)")
                        .font(.system(.caption2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    if isNext {
                        Text("NEXT")
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                Text(race.raceName)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("iPhone") {
    ContentView()
        .modelContainer(for: [RaceRecord.self, CircuitRecord.self, UserPreferences.self], inMemory: true)
}

#Preview("iPad") {
    ContentView()
        .modelContainer(for: [RaceRecord.self, CircuitRecord.self, UserPreferences.self], inMemory: true)
        .previewInterfaceOrientation(.landscapeLeft)
}
