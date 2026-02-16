import Foundation

/// Represents a Formula 1 circuit
struct Circuit: Codable, Identifiable, Hashable {
    var id: String { circuitId }
    
    let circuitId: String
    let circuitName: String
    let location: CircuitLocation
    
    enum CodingKeys: String, CodingKey {
        case circuitId
        case circuitName
        case location = "Location"
    }
}

/// Location details for a circuit
struct CircuitLocation: Codable, Hashable {
    let locality: String
    let country: String
    
    enum CodingKeys: String, CodingKey {
        case locality
        case country
    }
}

// MARK: - Preview Data
extension Circuit {
    static let preview = Circuit(
        circuitId: "bahrain",
        circuitName: "Bahrain International Circuit",
        location: CircuitLocation(locality: "Sakhir", country: "Bahrain")
    )
}
