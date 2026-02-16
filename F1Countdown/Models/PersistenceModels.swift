import Foundation
import SwiftData

// MARK: - Circuit Record (SwiftData)

/// Persistent storage model for Circuit data
@Model
final class CircuitRecord {
    @Attribute(.unique) var circuitId: String
    var circuitName: String
    var locality: String
    var country: String
    var lastUpdated: Date
    
    init(circuitId: String, circuitName: String, locality: String, country: String) {
        self.circuitId = circuitId
        self.circuitName = circuitName
        self.locality = locality
        self.country = country
        self.lastUpdated = Date()
    }
    
    /// Convert from API Circuit model
    convenience init(from circuit: Circuit) {
        self.init(
            circuitId: circuit.circuitId,
            circuitName: circuit.circuitName,
            locality: circuit.location.locality,
            country: circuit.location.country
        )
    }
    
    /// Convert to API Circuit model
    func toCircuit() -> Circuit {
        Circuit(
            circuitId: circuitId,
            circuitName: circuitName,
            location: CircuitLocation(locality: locality, country: country)
        )
    }
    
    /// Update from API Circuit model
    func update(from circuit: Circuit) {
        self.circuitName = circuit.circuitName
        self.locality = circuit.location.locality
        self.country = circuit.location.country
        self.lastUpdated = Date()
    }
}

// MARK: - Session Record (SwiftData)

/// Persistent storage model for session data within a race
@Model
final class SessionRecord {
    var sessionType: String
    var date: String
    var time: String?
    
    init(sessionType: String, date: String, time: String?) {
        self.sessionType = sessionType
        self.date = date
        self.time = time
    }
    
    /// Convert from API SessionData
    convenience init(from sessionData: SessionData, type: SessionType) {
        self.init(sessionType: type.rawValue, date: sessionData.date, time: sessionData.time)
    }
    
    /// Convert to SessionData
    func toSessionData() -> SessionData {
        SessionData(date: date, time: time)
    }
    
    /// Get SessionType from stored string
    var type: SessionType? {
        SessionType(rawValue: sessionType)
    }
}

// MARK: - Race Record (SwiftData)

/// Persistent storage model for Race data
@Model
final class RaceRecord {
    @Attribute(.unique) var id: String
    var season: String
    var round: String
    var raceName: String
    var date: String
    var time: String?
    var lastUpdated: Date
    var isCompleted: Bool
    
    // Relationship to circuit
    @Relationship(deleteRule: .nullify, inverse: \CircuitRecord.races)
    var circuit: CircuitRecord?
    
    // Sessions stored as JSON for simplicity
    var firstPracticeJSON: Data?
    var secondPracticeJSON: Data?
    var thirdPracticeJSON: Data?
    var qualifyingJSON: Data?
    var sprintJSON: Data?
    
    init(
        id: String,
        season: String,
        round: String,
        raceName: String,
        date: String,
        time: String?,
        circuit: CircuitRecord? = nil
    ) {
        self.id = id
        self.season = season
        self.round = round
        self.raceName = raceName
        self.date = date
        self.time = time
        self.circuit = circuit
        self.lastUpdated = Date()
        self.isCompleted = false
    }
    
    /// Convert from API Race model
    convenience init(from race: Race, circuit: CircuitRecord) {
        self.init(
            id: race.id,
            season: race.season,
            round: race.round,
            raceName: race.raceName,
            date: race.date,
            time: race.time,
            circuit: circuit
        )
        // Store sessions as JSON
        self.firstPracticeJSON = race.firstPractice.flatMap { try? JSONEncoder().encode($0) }
        self.secondPracticeJSON = race.secondPractice.flatMap { try? JSONEncoder().encode($0) }
        self.thirdPracticeJSON = race.thirdPractice.flatMap { try? JSONEncoder().encode($0) }
        self.qualifyingJSON = race.qualifying.flatMap { try? JSONEncoder().encode($0) }
        self.sprintJSON = race.sprint.flatMap { try? JSONEncoder().encode($0) }
    }
    
    /// Convert to API Race model
    func toRace() -> Race? {
        guard let circuit = circuit else { return nil }
        
        let circuitModel = circuit.toCircuit()
        
        // Decode sessions from JSON
        let fp1 = firstPracticeJSON.flatMap { try? JSONDecoder().decode(SessionData.self, from: $0) }
        let fp2 = secondPracticeJSON.flatMap { try? JSONDecoder().decode(SessionData.self, from: $0) }
        let fp3 = thirdPracticeJSON.flatMap { try? JSONDecoder().decode(SessionData.self, from: $0) }
        let qual = qualifyingJSON.flatMap { try? JSONDecoder().decode(SessionData.self, from: $0) }
        let sprintRace = sprintJSON.flatMap { try? JSONDecoder().decode(SessionData.self, from: $0) }
        
        return Race(
            season: season,
            round: round,
            raceName: raceName,
            circuit: circuitModel,
            date: date,
            time: time,
            firstPractice: fp1,
            secondPractice: fp2,
            thirdPractice: fp3,
            qualifying: qual,
            sprint: sprintRace
        )
    }
    
    /// Update from API Race model
    func update(from race: Race, circuit: CircuitRecord) {
        self.season = race.season
        self.round = race.round
        self.raceName = race.raceName
        self.date = race.date
        self.time = race.time
        self.circuit = circuit
        self.lastUpdated = Date()
        
        // Update sessions
        self.firstPracticeJSON = race.firstPractice.flatMap { try? JSONEncoder().encode($0) }
        self.secondPracticeJSON = race.secondPractice.flatMap { try? JSONEncoder().encode($0) }
        self.thirdPracticeJSON = race.thirdPractice.flatMap { try? JSONEncoder().encode($0) }
        self.qualifyingJSON = race.qualifying.flatMap { try? JSONEncoder().encode($0) }
        self.sprintJSON = race.sprint.flatMap { try? JSONEncoder().encode($0) }
    }
    
    /// Mark race as completed
    func markCompleted() {
        isCompleted = true
        lastUpdated = Date()
    }
    
    /// Check if race is upcoming
    var isUpcoming: Bool {
        guard let raceDateTime = toRace()?.raceDateTime else { return false }
        return raceDateTime > Date()
    }
}

// MARK: - CircuitRecord Relationship Extension

extension CircuitRecord {
    /// Races at this circuit (computed property for reverse relationship)
    var races: [RaceRecord] {
        (self as CircuitRecord)._races?.compactMap { $0 as? RaceRecord } ?? []
    }
    
    /// Internal storage for relationship (used by SwiftData)
    @Relationship
    var _races: [RaceRecord]?
}

// MARK: - Preview Data

extension CircuitRecord {
    static var preview: CircuitRecord {
        CircuitRecord(
            circuitId: "bahrain",
            circuitName: "Bahrain International Circuit",
            locality: "Sakhir",
            country: "Bahrain"
        )
    }
}

extension RaceRecord {
    static var preview: RaceRecord {
        let circuit = CircuitRecord.preview
        return RaceRecord(
            id: "2024-1",
            season: "2024",
            round: "1",
            raceName: "Bahrain Grand Prix",
            date: "2024-03-02",
            time: "15:00:00Z",
            circuit: circuit
        )
    }
}

// MARK: - SwiftData Container Configuration

/// SwiftData container configuration for the app
enum DataContainer {
    /// The main SwiftData container
    static let container: ModelContainer = {
        let schema = Schema([
            RaceRecord.self,
            CircuitRecord.self,
            SessionRecord.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier("group.com.f1countdown.app"),
            cloudKitDatabase: .private("iCloud.com.f1countdown.app")
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            // Fallback to local-only storage if CloudKit is unavailable
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            return try! ModelContainer(
                for: schema,
                configurations: localConfig
            )
        }
    }()
    
    /// Preview container for SwiftUI previews
    static var previewContainer: ModelContainer = {
        let schema = Schema([
            RaceRecord.self,
            CircuitRecord.self,
            SessionRecord.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: false
        )
        
        let container = try! ModelContainer(
            for: schema,
            configurations: configuration
        )
        
        // Add preview data
        let context = container.mainContext
        let circuit = CircuitRecord.preview
        context.insert(circuit)
        
        let race = RaceRecord.preview
        race.circuit = circuit
        context.insert(race)
        
        return container
    }()
}
