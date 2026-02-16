import Foundation
import SwiftUI

// MARK: - Race List View Model

/// ViewModel for displaying and managing a list of races
@MainActor
final class RaceListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All races for the current view
    @Published private(set) var races: [Race] = []
    
    /// Filtered races based on current filter
    @Published private(set) var filteredRaces: [Race] = []
    
    /// Loading state
    @Published private(set) var isLoading: Bool = false
    
    /// Error message if any
    @Published var errorMessage: String?
    
    /// Currently selected season
    @Published var selectedSeason: Int? {
        didSet { Task { await refresh() } }
    }
    
    /// Filter mode
    @Published var filterMode: RaceFilterMode = .all {
        didSet { applyFilter() }
    }
    
    /// Search query
    @Published var searchQuery: String = "" {
        didSet { applyFilter() }
    }
    
    /// Pull-to-refresh trigger
    @Published var isRefreshing: Bool = false
    
    // MARK: - Private Properties
    
    private let dataService: DataService
    private let preferencesManager: PreferencesManager
    
    /// Available seasons for selection
    private(set) var availableSeasons: [Int] = []
    
    // MARK: - Computed Properties
    
    /// Upcoming races
    var upcomingRaces: [Race] {
        filteredRaces.filter { $0.isUpcoming }
    }
    
    /// Completed races
    var completedRaces: [Race] {
        filteredRaces.filter { !$0.isUpcoming }
    }
    
    /// Next race
    var nextRace: Race? {
        upcomingRaces.sorted {
            ($0.raceDateTime ?? .distantFuture) < ($1.raceDateTime ?? .distantFuture)
        }.first
    }
    
    /// Current season year
    var currentSeason: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    // MARK: - Initialization
    
    init(dataService: DataService, preferencesManager: PreferencesManager = .shared) {
        self.dataService = dataService
        self.preferencesManager = preferencesManager
        
        // Set default season
        selectedSeason = currentSeason
        
        // Initialize available seasons (current year and past 5 years)
        let currentYear = currentSeason
        availableSeasons = Array((currentYear - 5)...currentYear).reversed()
        
        // Load initial data
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Load initial data
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load cached data first
        let season = selectedSeason?.description
        let cached = await dataService.getCachedRaces(season: season)
        
        if !cached.isEmpty {
            races = cached
            applyFilter()
        }
        
        // Then refresh from network
        do {
            try await refresh()
        } catch {
            if races.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Refresh race data
    func refresh() async {
        // Skip refresh if already loading
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let season = selectedSeason
            races = try await dataService.fetchAndCacheRaces(year: season)
            applyFilter()
            errorMessage = nil
        } catch {
            // On error, keep cached data
            if races.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Pull-to-refresh action
    func refreshFromPullToRefresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        await refresh()
    }
    
    /// Select a different season
    func selectSeason(_ year: Int) {
        selectedSeason = year
    }
    
    /// Toggle filter mode
    func setFilterMode(_ mode: RaceFilterMode) {
        filterMode = mode
    }
    
    /// Clear search query
    func clearSearch() {
        searchQuery = ""
    }
    
    /// Get countdown string for a race
    func countdownString(for race: Race) -> String {
        guard let dateTime = race.raceDateTime else {
            return "Date TBA"
        }
        
        let now = Date()
        let interval = dateTime.timeIntervalSince(now)
        
        if interval <= 0 {
            return "Completed"
        }
        
        let days = Int(interval / 86400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Check if a circuit is favorited
    func isFavoriteCircuit(_ circuitId: String) -> Bool {
        preferencesManager.preferences.isFavoriteCircuit(circuitId)
    }
    
    /// Toggle favorite status for a circuit
    func toggleFavoriteCircuit(_ circuitId: String) {
        preferencesManager.toggleFavoriteCircuit(circuitId)
        // Trigger UI update
        objectWillChange.send()
    }
    
    // MARK: - Private Methods
    
    /// Apply current filter to races
    private func applyFilter() {
        var result = races
        
        // Apply filter mode
        switch filterMode {
        case .all:
            break
        case .upcoming:
            result = result.filter { $0.isUpcoming }
        case .completed:
            result = result.filter { !$0.isUpcoming }
        case .favorites:
            let favoriteIds = preferencesManager.preferences.favoriteCircuitIds
            result = result.filter { favoriteIds.contains($0.circuit.circuitId) }
        }
        
        // Apply search query
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.raceName.lowercased().contains(query) ||
                $0.circuit.circuitName.lowercased().contains(query) ||
                $0.circuit.location.locality.lowercased().contains(query) ||
                $0.circuit.location.country.lowercased().contains(query)
            }
        }
        
        filteredRaces = result
    }
}

// MARK: - Race Filter Mode

/// Filter modes for race list
enum RaceFilterMode: String, CaseIterable {
    case all = "All"
    case upcoming = "Upcoming"
    case completed = "Completed"
    case favorites = "Favorites"
    
    var displayName: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .upcoming: return "clock"
        case .completed: return "checkmark.circle"
        case .favorites: return "heart.fill"
        }
    }
}

// MARK: - Preview Support

extension RaceListViewModel {
    /// Create a preview view model
    static var preview: RaceListViewModel {
        let container = try! ModelContainer(
            for: RaceRecord.self, CircuitRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let dataService = DataService(modelContext: container.mainContext)
        return RaceListViewModel(dataService: dataService)
    }
}
