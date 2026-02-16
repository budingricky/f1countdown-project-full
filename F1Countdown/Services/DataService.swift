import Foundation
import SwiftData
import CloudKit
import BackgroundTasks

// MARK: - Data Service Error

/// Errors that can occur during data operations
enum DataServiceError: Error, LocalizedError {
    case noCachedData
    case syncFailed(Error)
    case cacheError(Error)
    case networkUnavailable
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .noCachedData:
            return "No cached data available"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .cacheError(let error):
            return "Cache error: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network unavailable"
        case .invalidData:
            return "Invalid data"
        }
    }
}

// MARK: - Data Service

/// Service responsible for data persistence, caching, and CloudKit synchronization
@MainActor
final class DataService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently cached races
    @Published private(set) var cachedRaces: [Race] = []
    
    /// Loading state
    @Published private(set) var isLoading: Bool = false
    
    /// Last sync date
    @Published private(set) var lastSyncDate: Date?
    
    /// Sync error if any
    @Published private(set) var lastError: DataServiceError?
    
    /// Network availability
    @Published private(set) var isNetworkAvailable: Bool = true
    
    // MARK: - Private Properties
    
    /// SwiftData model context
    private let modelContext: ModelContext
    
    /// API client for network requests
    private let apiClient: APIClient
    
    /// CloudKit container
    private let cloudKitContainer: CKContainer?
    
    /// Background refresh task identifier
    static let backgroundRefreshTaskIdentifier = "com.f1countdown.refresh"
    
    /// Minimum refresh interval
    private let minimumRefreshInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    /// Initialize with model context and optional API client
    init(modelContext: ModelContext, apiClient: APIClient = .shared) {
        self.modelContext = modelContext
        self.apiClient = apiClient
        
        // Initialize CloudKit container
        self.cloudKitContainer = CKContainer(identifier: "iCloud.com.f1countdown.app")
        
        // Load cached data
        Task {
            await loadCachedRaces()
        }
        
        // Start monitoring network
        startNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Fetch and cache races for a specific season
    /// - Parameter year: The season year, or nil for current season
    /// - Returns: Array of Race objects
    func fetchAndCacheRaces(year: Int? = nil) async throws -> [Race] {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        do {
            // Fetch from API
            let races: [Race]
            if let year = year {
                races = try await apiClient.fetchSeason(year: year)
            } else {
                races = try await apiClient.fetchCurrentSeason()
            }
            
            // Cache to SwiftData
            try cacheRaces(races)
            
            // Update state
            cachedRaces = races
            lastSyncDate = Date()
            
            return races
        } catch let error as APIError {
            // Handle API errors
            if case .networkError = error {
                isNetworkAvailable = false
                throw DataServiceError.networkUnavailable
            }
            throw DataServiceError.syncFailed(error)
        } catch {
            throw DataServiceError.syncFailed(error)
        }
    }
    
    /// Get cached races from local storage
    /// - Parameter season: Optional season filter
    /// - Returns: Array of cached Race objects
    func getCachedRaces(season: String? = nil) async -> [Race] {
        let descriptor: FetchDescriptor<RaceRecord>
        
        if let season = season {
            descriptor = FetchDescriptor<RaceRecord>(
                predicate: #Predicate { $0.season == season },
                sortBy: [SortDescriptor(\.round, order: .forward)]
            )
        } else {
            descriptor = FetchDescriptor<RaceRecord>(
                sortBy: [SortDescriptor(\.season, order: .reverse), SortDescriptor(\.round, order: .forward)]
            )
        }
        
        do {
            let records = try modelContext.fetch(descriptor)
            let races = records.compactMap { $0.toRace() }
            cachedRaces = races
            return races
        } catch {
            print("Failed to fetch cached races: \(error)")
            return []
        }
    }
    
    /// Get a specific cached race by ID
    /// - Parameter id: The race ID (e.g., "2024-1")
    /// - Returns: The cached Race, or nil if not found
    func getCachedRace(id: String) async -> Race? {
        let descriptor = FetchDescriptor<RaceRecord>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let records = try modelContext.fetch(descriptor)
            return records.first?.toRace()
        } catch {
            print("Failed to fetch cached race: \(error)")
            return nil
        }
    }
    
    /// Sync data with CloudKit
    func syncWithCloudKit() async throws {
        // Check CloudKit account status
        guard let container = cloudKitContainer else {
            throw DataServiceError.syncFailed(NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit not configured"]))
        }
        
        do {
            let status = try await container.accountStatus()
            guard status == .available else {
                // CloudKit not available, continue with local-only storage
                print("CloudKit not available: \(status.rawValue)")
                return
            }
            
            // SwiftData with CloudKit integration handles sync automatically
            // Just ensure we save any pending changes
            try modelContext.save()
            
            // Verify database access
            _ = try await container.privateCloudDatabase.databaseStatus()
            
        } catch {
            throw DataServiceError.syncFailed(error)
        }
    }
    
    /// Schedule background refresh
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundRefreshTaskIdentifier)
        
        // Schedule for next appropriate time
        request.earliestBeginDate = Date(timeIntervalSinceNow: minimumRefreshInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled")
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }
    
    /// Handle background refresh task
    func handleBackgroundRefresh(task: BGAppRefreshTask) async {
        // Schedule next refresh
        scheduleBackgroundRefresh()
        
        do {
            // Fetch latest data
            _ = try await fetchAndCacheRaces()
            
            // Sync with CloudKit
            try await syncWithCloudKit()
            
            task.setTaskCompleted(success: true)
        } catch {
            print("Background refresh failed: \(error)")
            task.setTaskCompleted(success: false)
        }
    }
    
    /// Refresh data if needed based on last sync time
    func refreshIfNeeded() async throws {
        guard shouldRefresh() else { return }
        _ = try await fetchAndCacheRaces()
    }
    
    /// Clear all cached data
    func clearCache() async throws {
        do {
            // Delete all race records
            try modelContext.delete(model: RaceRecord.self)
            
            // Delete all circuit records (will cascade delete due to relationship)
            try modelContext.delete(model: CircuitRecord.self)
            
            // Save changes
            try modelContext.save()
            
            // Clear in-memory cache
            cachedRaces = []
            lastSyncDate = nil
        } catch {
            throw DataServiceError.cacheError(error)
        }
    }
    
    /// Get upcoming races from cache
    func getUpcomingRaces() -> [Race] {
        cachedRaces.filter { $0.isUpcoming }
    }
    
    /// Get the next upcoming race
    func getNextRace() -> Race? {
        getUpcomingRaces()
            .sorted { ($0.raceDateTime ?? .distantFuture) < ($1.raceDateTime ?? .distantFuture) }
            .first
    }
    
    /// Get completed races from cache
    func getCompletedRaces() -> [Race] {
        cachedRaces.filter { !$0.isUpcoming }
    }
    
    // MARK: - Private Methods
    
    /// Load cached races on initialization
    private func loadCachedRaces() async {
        _ = await getCachedRaces()
    }
    
    /// Cache races to SwiftData
    private func cacheRaces(_ races: [Race]) throws {
        for race in races {
            // Check if circuit already exists
            let circuitDescriptor = FetchDescriptor<CircuitRecord>(
                predicate: #Predicate { $0.circuitId == race.circuit.circuitId }
            )
            
            let existingCircuits = try modelContext.fetch(circuitDescriptor)
            let circuitRecord: CircuitRecord
            
            if let existing = existingCircuits.first {
                existing.update(from: race.circuit)
                circuitRecord = existing
            } else {
                circuitRecord = CircuitRecord(from: race.circuit)
                modelContext.insert(circuitRecord)
            }
            
            // Check if race already exists
            let raceDescriptor = FetchDescriptor<RaceRecord>(
                predicate: #Predicate { $0.id == race.id }
            )
            
            let existingRaces = try modelContext.fetch(raceDescriptor)
            
            if let existing = existingRaces.first {
                existing.update(from: race, circuit: circuitRecord)
            } else {
                let raceRecord = RaceRecord(from: race, circuit: circuitRecord)
                modelContext.insert(raceRecord)
            }
        }
        
        try modelContext.save()
    }
    
    /// Check if refresh is needed
    private func shouldRefresh() -> Bool {
        guard let lastSync = lastSyncDate else { return true }
        return Date().timeIntervalSince(lastSync) >= minimumRefreshInterval
    }
    
    /// Start monitoring network availability
    private func startNetworkMonitoring() {
        // Use NWPathMonitor for real network monitoring
        // For now, we'll rely on API errors to detect network issues
    }
}

// MARK: - Background Task Handler

/// Background task handler for the app
final class BackgroundTaskHandler {
    static let shared = BackgroundTaskHandler()
    
    private init() {}
    
    /// Register background tasks
    func registerBackgroundTasks(with dataService: DataService) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: DataService.backgroundRefreshTaskIdentifier,
            using: nil
        ) { task in
            Task {
                await dataService.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
            }
        }
    }
}

// MARK: - CloudKit Record Types

/// CloudKit record type definitions
enum CloudKitRecordType {
    static let race = "RaceRecord"
    static let circuit = "CircuitRecord"
    static let userPreferences = "UserPreferences"
    
    /// Field names for Race record
    enum RaceFields {
        static let id = "id"
        static let season = "season"
        static let round = "round"
        static let raceName = "raceName"
        static let date = "date"
        static let time = "time"
        static let circuit = "circuit"
        static let lastUpdated = "lastUpdated"
        static let isCompleted = "isCompleted"
    }
    
    /// Field names for Circuit record
    enum CircuitFields {
        static let circuitId = "circuitId"
        static let circuitName = "circuitName"
        static let locality = "locality"
        static let country = "country"
        static let lastUpdated = "lastUpdated"
    }
}

// MARK: - Preview Support

extension DataService {
    /// Create a preview data service with in-memory storage
    static var preview: DataService {
        let container = try! ModelContainer(
            for: RaceRecord.self, CircuitRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = DataService(modelContext: container.mainContext)
        
        // Add preview data
        Task {
            let previewRaces = [Race.preview]
            try? service.cacheRaces(previewRaces)
            await service.loadCachedRaces()
        }
        
        return service
    }
}
