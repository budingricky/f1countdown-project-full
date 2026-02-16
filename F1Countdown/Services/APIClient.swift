import Foundation

/// API Client for Jolpica-F1 API
/// Handles fetching Formula 1 schedule data
/// Rate limit: 500 requests per hour
final class APIClient {
    
    // MARK: - Properties
    
    /// Base URL for Jolpica-F1 API
    static let baseURL = "https://api.jolpi.ca/ergast/f1"
    
    /// Shared singleton instance
    static let shared = APIClient()
    
    /// URL session for network requests
    private let session: URLSession
    
    /// Rate limit tracking
    private var requestCount: Int = 0
    private var lastRequestTime: Date?
    private let maxRequestsPerHour = 500
    
    // MARK: - Initialization
    
    /// Initialize with custom URL session (useful for testing)
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public API
    
    /// Fetches all races for a specific season
    /// - Parameter year: The season year (e.g., 2024)
    /// - Returns: Array of Race objects for the season
    func fetchSeason(year: Int) async throws -> [Race] {
        let urlString = "\(Self.baseURL)/\(year).json"
        return try await fetchRaces(from: urlString)
    }
    
    /// Fetches all races for the current season
    /// - Returns: Array of Race objects for the current season
    func fetchCurrentSeason() async throws -> [Race] {
        let urlString = "\(Self.baseURL)/current.json"
        return try await fetchRaces(from: urlString)
    }
    
    /// Fetches the next upcoming race
    /// - Returns: The next Race, or nil if no upcoming race found
    func fetchNextRace() async throws -> Race? {
        let urlString = "\(Self.baseURL)/current/next.json"
        let races = try await fetchRaces(from: urlString)
        return races.first
    }
    
    // MARK: - Private Methods
    
    /// Fetches and decodes races from a URL
    private func fetchRaces(from urlString: String) async throws -> [Race] {
        // Check rate limit
        try checkRateLimit()
        
        // Validate URL
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Make request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        
        // Update rate limit tracking
        updateRateLimitTracking()
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle status codes
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Int($0) }
            throw APIError.rateLimitExceeded(retryAfter: retryAfter)
        case 400...499:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        case 500...599:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Decode response
        do {
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            return apiResponse.mrData.raceTable?.races ?? []
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// Checks if we're within rate limits
    private func checkRateLimit() throws {
        let now = Date()
        
        // Reset counter if an hour has passed
        if let lastRequest = lastRequestTime {
            let hourAgo = now.addingTimeInterval(-3600)
            if lastRequest < hourAgo {
                requestCount = 0
            }
        }
        
        // Check if we've exceeded the limit
        if requestCount >= maxRequestsPerHour {
            throw APIError.rateLimitExceeded(retryAfter: nil)
        }
    }
    
    /// Updates rate limit tracking after a request
    private func updateRateLimitTracking() {
        requestCount += 1
        lastRequestTime = Date()
    }
    
    // MARK: - Testing Helpers
    
    /// Resets rate limit tracking (for testing only)
    func resetRateLimit() {
        requestCount = 0
        lastRequestTime = nil
    }
    
    /// Returns current request count (for testing only)
    var currentRequestCount: Int {
        return requestCount
    }
}
