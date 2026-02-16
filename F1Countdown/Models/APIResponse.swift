import Foundation

/// Root response wrapper from Jolpica-F1 API
struct APIResponse: Codable {
    let mrData: MRData
    
    enum CodingKeys: String, CodingKey {
        case mrData = "MRData"
    }
}

/// Main data container from API
struct MRData: Codable {
    let xmlns: String?
    let series: String
    let url: String
    let limit: String
    let offset: String
    let total: String
    let raceTable: RaceTable?
    
    enum CodingKeys: String, CodingKey {
        case xmlns
        case series
        case url
        case limit
        case offset
        case total
        case raceTable = "RaceTable"
    }
}

/// Race table containing season info and races
struct RaceTable: Codable {
    let season: String?
    let round: String?
    let races: [Race]
    
    enum CodingKeys: String, CodingKey {
        case season
        case round
        case races = "Races"
    }
}

// MARK: - API Error Types

/// Errors that can occur during API operations
enum APIError: Error, LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case rateLimitExceeded(retryAfter: Int?)
    case invalidResponse
    case invalidURL
    case noData
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .rateLimitExceeded(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limit exceeded. Try again in \(seconds) seconds."
            }
            return "Rate limit exceeded. Please wait before making more requests."
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        }
    }
}
