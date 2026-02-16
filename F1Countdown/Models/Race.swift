import Foundation

/// Represents a Formula 1 race event
struct Race: Codable, Identifiable, Hashable {
    var id: String { "\(season)-\(round)" }
    
    let season: String
    let round: String
    let raceName: String
    let circuit: Circuit
    let date: String
    let time: String?
    
    // Optional sessions - may not be present in all API responses
    let firstPractice: SessionData?
    let secondPractice: SessionData?
    let thirdPractice: SessionData?
    let qualifying: SessionData?
    let sprint: SessionData?
    
    enum CodingKeys: String, CodingKey {
        case season
        case round
        case raceName
        case circuit = "Circuit"
        case date
        case time
        case firstPractice = "FirstPractice"
        case secondPractice = "SecondPractice"
        case thirdPractice = "ThirdPractice"
        case qualifying = "Qualifying"
        case sprint = "Sprint"
    }
    
    /// Returns all sessions for this race weekend in chronological order
    var sessions: [Session] {
        var allSessions: [Session] = []
        
        if let fp1 = firstPractice {
            allSessions.append(Session(type: .fp1, date: fp1.date, time: fp1.time))
        }
        if let fp2 = secondPractice {
            allSessions.append(Session(type: .fp2, date: fp2.date, time: fp2.time))
        }
        if let fp3 = thirdPractice {
            allSessions.append(Session(type: .fp3, date: fp3.date, time: fp3.time))
        }
        if let sprint = sprint {
            allSessions.append(Session(type: .sprint, date: sprint.date, time: sprint.time))
        }
        if let qual = qualifying {
            allSessions.append(Session(type: .qualifying, date: qual.date, time: qual.time))
        }
        
        // Main race is always present
        allSessions.append(Session(type: .race, date: date, time: time))
        
        return allSessions.sorted { $0.dateTime ?? Date.distantPast < $1.dateTime ?? Date.distantPast }
    }
    
    /// Returns the full datetime for the race
    var raceDateTime: Date? {
        guard let time = time else {
            return ISO8601DateFormatter().date(from: date)
        }
        let dateTimeString = "\(date)T\(time)"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateTimeString)
    }
    
    /// Returns true if this race is in the future
    var isUpcoming: Bool {
        guard let raceDate = raceDateTime else { return false }
        return raceDate > Date()
    }
}

/// Lightweight session data from API
struct SessionData: Codable, Hashable {
    let date: String
    let time: String?
}

// MARK: - Preview Data
extension Race {
    static let preview = Race(
        season: "2024",
        round: "1",
        raceName: "Bahrain Grand Prix",
        circuit: .preview,
        date: "2024-03-02",
        time: "15:00:00Z",
        firstPractice: SessionData(date: "2024-02-29", time: "11:30:00Z"),
        secondPractice: SessionData(date: "2024-02-29", time: "15:00:00Z"),
        thirdPractice: SessionData(date: "2024-03-01", time: "12:30:00Z"),
        qualifying: SessionData(date: "2024-03-01", time: "16:00:00Z"),
        sprint: nil
    )
}
