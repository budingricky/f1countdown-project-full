import Foundation

/// Represents a session type in Formula 1
enum SessionType: String, Codable, CaseIterable {
    case fp1 = "FirstPractice"
    case fp2 = "SecondPractice"
    case fp3 = "ThirdPractice"
    case qualifying = "Qualifying"
    case sprint = "Sprint"
    case race = "Race"
    
    var displayName: String {
        switch self {
        case .fp1: return "Free Practice 1"
        case .fp2: return "Free Practice 2"
        case .fp3: return "Free Practice 3"
        case .qualifying: return "Qualifying"
        case .sprint: return "Sprint"
        case .race: return "Race"
        }
    }
    
    var shortName: String {
        switch self {
        case .fp1: return "FP1"
        case .fp2: return "FP2"
        case .fp3: return "FP3"
        case .qualifying: return "Q"
        case .sprint: return "Sprint"
        case .race: return "Race"
        }
    }
}

/// Represents a session during a race weekend
struct Session: Codable, Identifiable, Hashable {
    var id: String { "\(type.rawValue)-\(date)-\(time ?? "")" }
    
    let type: SessionType
    let date: String
    let time: String?
    
    /// Returns the full datetime for this session
    var dateTime: Date? {
        let dateTimeString = time != nil ? "\(date)T\(time!)" : date
        let formatters: [ISO8601DateFormatter] = {
            let f1 = ISO8601DateFormatter()
            f1.formatOptions = [.withInternetDateTime]
            let f2 = ISO8601DateFormatter()
            f2.formatOptions = [.withFullDate]
            return [f1, f2]
        }()
        
        for formatter in formatters {
            if let date = formatter.date(from: dateTimeString) {
                return date
            }
        }
        return nil
    }
}

// MARK: - Preview Data
extension Session {
    static let preview = Session(
        type: .race,
        date: "2024-03-02",
        time: "15:00:00Z"
    )
}
