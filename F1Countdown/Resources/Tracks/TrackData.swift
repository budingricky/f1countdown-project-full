//
//  TrackData.swift
//  F1Countdown
//
//  F1 Circuit data model for track visualization
//

import Foundation
import SwiftUI

/// Represents an F1 circuit with its visual and metadata properties
struct TrackData: Identifiable, Hashable {
    let id: String
    let circuitId: String
    let circuitName: String
    let country: String
    let locality: String
    let countryFlag: String // Emoji flag
    let primaryColor: Color
    let secondaryColor: Color
    let turnCount: Int
    let trackLength: Double // in km
    let lapRecord: String?
    
    /// Returns the circuit path for drawing
    var path: Path {
        CircuitPaths.path(for: circuitId)
    }
    
    // MARK: - Sample Tracks
    
    static let bahrain = TrackData(
        id: "bahrain",
        circuitId: "bahrain",
        circuitName: "Bahrain International Circuit",
        country: "Bahrain",
        locality: "Sakhir",
        countryFlag: "🇧🇭",
        primaryColor: Color(red: 0.8, green: 0.1, blue: 0.1),
        secondaryColor: Color(red: 1.0, green: 0.95, blue: 0.9),
        turnCount: 15,
        trackLength: 5.412,
        lapRecord: "1:31.447"
    )
    
    static let monaco = TrackData(
        id: "monaco",
        circuitId: "monaco",
        circuitName: "Circuit de Monaco",
        country: "Monaco",
        locality: "Monte Carlo",
        countryFlag: "🇲🇨",
        primaryColor: Color(red: 0.0, green: 0.2, blue: 0.5),
        secondaryColor: Color(red: 1.0, green: 0.85, blue: 0.0),
        turnCount: 19,
        trackLength: 3.337,
        lapRecord: "1:12.909"
    )
    
    static let silverstone = TrackData(
        id: "silverstone",
        circuitId: "silverstone",
        circuitName: "Silverstone Circuit",
        country: "United Kingdom",
        locality: "Silverstone",
        countryFlag: "🇬🇧",
        primaryColor: Color(red: 0.0, green: 0.3, blue: 0.7),
        secondaryColor: Color(red: 0.9, green: 0.9, blue: 0.95),
        turnCount: 18,
        trackLength: 5.891,
        lapRecord: "1:27.097"
    )
    
    static let monza = TrackData(
        id: "monza",
        circuitId: "monza",
        circuitName: "Autodromo Nazionale Monza",
        country: "Italy",
        locality: "Monza",
        countryFlag: "🇮🇹",
        primaryColor: Color(red: 0.8, green: 0.0, blue: 0.0),
        secondaryColor: Color(red: 0.0, green: 0.5, blue: 0.0),
        turnCount: 11,
        trackLength: 5.793,
        lapRecord: "1:21.046"
    )
    
    static let suzuka = TrackData(
        id: "suzuka",
        circuitId: "suzuka",
        circuitName: "Suzuka International Racing Course",
        country: "Japan",
        locality: "Suzuka",
        countryFlag: "🇯🇵",
        primaryColor: Color(red: 0.9, green: 0.0, blue: 0.2),
        secondaryColor: Color(red: 1.0, green: 1.0, blue: 1.0),
        turnCount: 18,
        trackLength: 5.807,
        lapRecord: "1:30.983"
    )
    
    /// All available tracks
    static let allTracks: [TrackData] = [
        .bahrain,
        .monaco,
        .silverstone,
        .monza,
        .suzuka
    ]
    
    /// Find track by circuit ID
    static func find(by circuitId: String) -> TrackData? {
        allTracks.first { $0.circuitId == circuitId }
    }
}

// MARK: - Hashable Conformance

extension TrackData {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TrackData, rhs: TrackData) -> Bool {
        lhs.id == rhs.id
    }
}
