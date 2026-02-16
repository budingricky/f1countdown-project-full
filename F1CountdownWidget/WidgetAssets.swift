//
//  WidgetAssets.swift
//  F1CountdownWidget
//
//  Shared assets, colors, and styles for F1 countdown widgets
//

import SwiftUI

// MARK: - Widget Colors

/// F1-themed color palette for widgets
enum F1WidgetColors {
    // Primary F1 Red
    static let f1Red = Color(red: 255/255, green: 0/255, blue: 0/255)
    static let f1RedDark = Color(red: 180/255, green: 0/255, blue: 0/255)
    
    // Accent colors
    static let f1Yellow = Color(red: 255/255, green: 230/255, blue: 0/255)
    static let f1Orange = Color(red: 255/255, green: 140/255, blue: 0/255)
    
    // Background colors
    static let darkBackground = Color(red: 20/255, green: 20/255, blue: 25/255)
    static let cardBackground = Color(red: 35/255, green: 35/255, blue: 40/255)
    
    // Text colors
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let tertiaryText = Color.white.opacity(0.5)
    
    // Gradient for countdown display
    static func countdownGradient(isLive: Bool = false) -> LinearGradient {
        if isLive {
            return LinearGradient(
                colors: [f1Red, f1Orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [f1Red, f1RedDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Track colors by circuit ID
    static func trackColor(for circuitId: String) -> Color {
        switch circuitId {
        case "bahrain":
            return Color(red: 0.8, green: 0.1, blue: 0.1)
        case "monaco":
            return Color(red: 0.0, green: 0.2, blue: 0.5)
        case "silverstone":
            return Color(red: 0.0, green: 0.3, blue: 0.7)
        case "monza":
            return Color(red: 0.8, green: 0.0, blue: 0.0)
        case "suzuka":
            return Color(red: 0.9, green: 0.0, blue: 0.2)
        case "jeddah":
            return Color(red: 0.0, green: 0.5, blue: 0.3)
        case "albert_park":
            return Color(red: 0.0, green: 0.6, blue: 0.3)
        default:
            return f1Red
        }
    }
}

// MARK: - Widget Fonts

/// Typography styles for widgets
enum F1WidgetFonts {
    // Display font for countdown numbers
    static let countdown = Font.system(.largeTitle, design: .rounded)
        .weight(.bold)
        .monospacedDigit()
    
    // Title font
    static let title = Font.system(.headline, design: .rounded)
        .weight(.semibold)
    
    // Subtitle font
    static let subtitle = Font.system(.subheadline, design: .rounded)
        .weight(.medium)
    
    // Caption font
    static let caption = Font.system(.caption, design: .rounded)
        .weight(.regular)
    
    // Tiny font for compact displays
    static let tiny = Font.system(size: 10, weight: .medium, design: .rounded)
}

// MARK: - Widget Shapes

/// Custom shapes for widget backgrounds
struct WidgetBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    F1WidgetColors.darkBackground,
                    F1WidgetColors.darkBackground.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle noise texture overlay
            Color.black.opacity(0.1)
            
            // Corner accent
            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(F1WidgetColors.f1Red.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .offset(x: 30, y: -30)
                }
                Spacer()
            }
        }
    }
}

/// Checkered flag pattern for accents
struct CheckeredAccent: View {
    var size: CGFloat = 8
    var rows: Int = 3
    var columns: Int = 3
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<columns, id: \.self) { col in
                        Rectangle()
                            .fill((row + col) % 2 == 0 ? Color.white : Color.black)
                            .frame(width: size, height: size)
                    }
                }
            }
        }
    }
}

// MARK: - Circuit Shape for Widgets

/// Simplified circuit shape for widget display
struct WidgetCircuitShape: Shape {
    let circuitId: String
    
    func path(in rect: CGRect) -> Path {
        // Simplified circuit representations for widgets
        switch circuitId {
        case "bahrain":
            return bahrainWidgetPath(in: rect)
        case "monaco":
            return monacoWidgetPath(in: rect)
        case "silverstone":
            return silverstoneWidgetPath(in: rect)
        case "monza":
            return monzaWidgetPath(in: rect)
        case "suzuka":
            return suzukaWidgetPath(in: rect)
        default:
            return defaultWidgetPath(in: rect)
        }
    }
    
    // MARK: - Simplified Circuit Paths
    
    private func bahrainWidgetPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.5))
        path.addCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.35),
            control1: CGPoint(x: w * 0.85, y: h * 0.5),
            control2: CGPoint(x: w * 0.88, y: h * 0.42)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.75, y: h * 0.15),
            control1: CGPoint(x: w * 0.82, y: h * 0.28),
            control2: CGPoint(x: w * 0.78, y: h * 0.18)
        )
        path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.15))
        path.addCurve(
            to: CGPoint(x: w * 0.25, y: h * 0.35),
            control1: CGPoint(x: w * 0.32, y: h * 0.15),
            control2: CGPoint(x: w * 0.22, y: h * 0.25)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.45, y: h * 0.85),
            control1: CGPoint(x: w * 0.28, y: h * 0.5),
            control2: CGPoint(x: w * 0.38, y: h * 0.85)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.15, y: h * 0.5),
            control1: CGPoint(x: w * 0.35, y: h * 0.85),
            control2: CGPoint(x: w * 0.12, y: h * 0.65)
        )
        path.closeSubpath()
        return path
    }
    
    private func monacoWidgetPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.95))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.75))
        path.addCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.65),
            control1: CGPoint(x: w * 0.48, y: h * 0.7),
            control2: CGPoint(x: w * 0.4, y: h * 0.68)
        )
        path.addLine(to: CGPoint(x: w * 0.3, y: h * 0.4))
        path.addCurve(
            to: CGPoint(x: w * 0.3, y: h * 0.18),
            control1: CGPoint(x: w * 0.22, y: h * 0.32),
            control2: CGPoint(x: w * 0.25, y: h * 0.18)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.58, y: h * 0.3),
            control1: CGPoint(x: w * 0.38, y: h * 0.18),
            control2: CGPoint(x: w * 0.62, y: h * 0.24)
        )
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.35))
        path.addCurve(
            to: CGPoint(x: w * 0.75, y: h * 0.7),
            control1: CGPoint(x: w * 0.78, y: h * 0.38),
            control2: CGPoint(x: w * 0.76, y: h * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.88),
            control1: CGPoint(x: w * 0.66, y: h * 0.85),
            control2: CGPoint(x: w * 0.6, y: h * 0.88)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.95),
            control1: CGPoint(x: w * 0.5, y: h * 0.88),
            control2: CGPoint(x: w * 0.48, y: h * 0.92)
        )
        path.closeSubpath()
        return path
    }
    
    private func silverstoneWidgetPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.25, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.55))
        path.addCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.28),
            control1: CGPoint(x: w * 0.52, y: h * 0.52),
            control2: CGPoint(x: w * 0.72, y: h * 0.38)
        )
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.15))
        path.addCurve(
            to: CGPoint(x: w * 0.25, y: h * 0.42),
            control1: CGPoint(x: w * 0.4, y: h * 0.15),
            control2: CGPoint(x: w * 0.28, y: h * 0.3)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.25, y: h * 0.55),
            control1: CGPoint(x: w * 0.22, y: h * 0.46),
            control2: CGPoint(x: w * 0.22, y: h * 0.52)
        )
        path.closeSubpath()
        return path
    }
    
    private func monzaWidgetPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.3, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.5))
        path.addCurve(
            to: CGPoint(x: w * 0.72, y: h * 0.2),
            control1: CGPoint(x: w * 0.82, y: h * 0.48),
            control2: CGPoint(x: w * 0.78, y: h * 0.22)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.4, y: h * 0.18),
            control1: CGPoint(x: w * 0.68, y: h * 0.15),
            control2: CGPoint(x: w * 0.48, y: h * 0.16)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.22, y: h * 0.5),
            control1: CGPoint(x: w * 0.22, y: h * 0.28),
            control2: CGPoint(x: w * 0.2, y: h * 0.48)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.3, y: h * 0.5),
            control1: CGPoint(x: w * 0.24, y: h * 0.52),
            control2: CGPoint(x: w * 0.27, y: h * 0.52)
        )
        path.closeSubpath()
        return path
    }
    
    private func suzukaWidgetPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.6))
        path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.6))
        path.addCurve(
            to: CGPoint(x: w * 0.58, y: h * 0.25),
            control1: CGPoint(x: w * 0.52, y: h * 0.58),
            control2: CGPoint(x: w * 0.55, y: h * 0.38)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.42),
            control1: CGPoint(x: w * 0.64, y: h * 0.25),
            control2: CGPoint(x: w * 0.75, y: h * 0.35)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.75),
            control1: CGPoint(x: w * 0.82, y: h * 0.48),
            control2: CGPoint(x: w * 0.52, y: h * 0.7)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.2, y: h * 0.6),
            control1: CGPoint(x: w * 0.4, y: h * 0.82),
            control2: CGPoint(x: w * 0.18, y: h * 0.65)
        )
        path.closeSubpath()
        return path
    }
    
    private func defaultWidgetPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Generic oval shape
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.1))
        path.addCurve(
            to: CGPoint(x: w * 0.9, y: h * 0.5),
            control1: CGPoint(x: w * 0.85, y: h * 0.1),
            control2: CGPoint(x: w * 0.9, y: h * 0.3)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.9),
            control1: CGPoint(x: w * 0.9, y: h * 0.7),
            control2: CGPoint(x: w * 0.85, y: h * 0.9)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.1, y: h * 0.5),
            control1: CGPoint(x: w * 0.15, y: h * 0.9),
            control2: CGPoint(x: w * 0.1, y: h * 0.7)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.1),
            control1: CGPoint(x: w * 0.1, y: h * 0.3),
            control2: CGPoint(x: w * 0.15, y: h * 0.1)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Country Flag Mapping

/// Country flag emoji mapping
enum CountryFlags {
    static func flag(for country: String) -> String {
        switch country.lowercased() {
        case "bahrain": return "🇧🇭"
        case "saudi arabia": return "🇸🇦"
        case "australia": return "🇦🇺"
        case "japan": return "🇯🇵"
        case "china": return "🇨🇳"
        case "miami", "united states": return "🇺🇸"
        case "monaco": return "🇲🇨"
        case "azerbaijan": return "🇦🇿"
        case "canada": return "🇨🇦"
        case "great britain", "united kingdom": return "🇬🇧"
        case "hungary": return "🇭🇺"
        case "belgium": return "🇧🇪"
        case "netherlands": return "🇳🇱"
        case "italy": return "🇮🇹"
        case "singapore": return "🇸🇬"
        case "mexico": return "🇲🇽"
        case "brazil": return "🇧🇷"
        case "las vegas": return "🇺🇸"
        case "qatar": return "🇶🇦"
        case "abu dhabi", "united arab emirates": return "🇦🇪"
        case "spain": return "🇪🇸"
        case "austria": return "🇦🇹"
        case "france": return "🇫🇷"
        default: return "🏁"
        }
    }
}

// MARK: - Deep Link URLs

/// Deep link handling for widgets
enum WidgetDeepLinks {
    static let scheme = "f1countdown"
    
    /// URL to open race detail
    static func raceDetail(raceId: String) -> URL {
        URL(string: "\(scheme)://race/\(raceId)")!
    }
    
    /// URL to open countdown view
    static func countdown() -> URL {
        URL(string: "\(scheme)://countdown")!
    }
    
    /// URL to open schedule
    static func schedule() -> URL {
        URL(string: "\(scheme)://schedule")!
    }
}
