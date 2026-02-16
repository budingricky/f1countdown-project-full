//
//  CircuitPaths.swift
//  F1Countdown
//
//  SwiftUI Path definitions for F1 circuit visualizations
//  Uses normalized coordinates (0-1 range) for scalable rendering
//

import SwiftUI

/// Provides SwiftUI Path definitions for F1 circuits
enum CircuitPaths {
    
    /// Returns the path for a given circuit ID
    static func path(for circuitId: String) -> Path {
        switch circuitId {
        case "bahrain":
            return bahrainPath
        case "monaco":
            return monacoPath
        case "silverstone":
            return silverstonePath
        case "monza":
            return monzaPath
        case "suzuka":
            return suzukaPath
        default:
            return defaultPath
        }
    }
    
    // MARK: - Circuit Paths
    
    /// Bahrain International Circuit - Desert track with long straights
    /// Characteristic: Long main straight, tight turns, desert setting
    static var bahrainPath: Path {
        var path = Path()
        
        // Start at main straight
        path.move(to: CGPoint(x: 0.15, y: 0.5))
        
        // Main straight to turn 1
        path.addLine(to: CGPoint(x: 0.75, y: 0.5))
        
        // Turn 1-2 complex (tight right)
        path.addCurve(
            to: CGPoint(x: 0.85, y: 0.35),
            control1: CGPoint(x: 0.85, y: 0.5),
            control2: CGPoint(x: 0.88, y: 0.42)
        )
        
        // Turn 3-4 (sweeping left)
        path.addCurve(
            to: CGPoint(x: 0.75, y: 0.15),
            control1: CGPoint(x: 0.82, y: 0.28),
            control2: CGPoint(x: 0.78, y: 0.18)
        )
        
        // Back straight section
        path.addLine(to: CGPoint(x: 0.45, y: 0.15))
        
        // Turn 5-6 complex
        path.addCurve(
            to: CGPoint(x: 0.30, y: 0.22),
            control1: CGPoint(x: 0.38, y: 0.15),
            control2: CGPoint(x: 0.32, y: 0.18)
        )
        
        // Inner loop turns 7-10
        path.addCurve(
            to: CGPoint(x: 0.25, y: 0.35),
            control1: CGPoint(x: 0.25, y: 0.25),
            control2: CGPoint(x: 0.22, y: 0.30)
        )
        
        // Turns 11-12
        path.addCurve(
            to: CGPoint(x: 0.30, y: 0.65),
            control1: CGPoint(x: 0.28, y: 0.42),
            control2: CGPoint(x: 0.25, y: 0.58)
        )
        
        // Turns 13-14 complex
        path.addCurve(
            to: CGPoint(x: 0.45, y: 0.85),
            control1: CGPoint(x: 0.35, y: 0.75),
            control2: CGPoint(x: 0.42, y: 0.85)
        )
        
        // Final corner complex
        path.addCurve(
            to: CGPoint(x: 0.15, y: 0.5),
            control1: CGPoint(x: 0.35, y: 0.85),
            control2: CGPoint(x: 0.12, y: 0.65)
        )
        
        path.closeSubpath()
        return path
    }
    
    /// Circuit de Monaco - Street circuit, tight and twisty
    /// Characteristic: Narrow, many corners, harbor section, tunnel
    static var monacoPath: Path {
        var path = Path()
        
        // Start at main straight (start/finish)
        path.move(to: CGPoint(x: 0.5, y: 0.95))
        
        // Main straight up
        path.addLine(to: CGPoint(x: 0.5, y: 0.75))
        
        // Sainte Devote (turn 1)
        path.addCurve(
            to: CGPoint(x: 0.35, y: 0.65),
            control1: CGPoint(x: 0.48, y: 0.70),
            control2: CGPoint(x: 0.40, y: 0.68)
        )
        
        // Beau Rivage uphill
        path.addLine(to: CGPoint(x: 0.30, y: 0.40))
        
        // Massenet (turn 3)
        path.addCurve(
            to: CGPoint(x: 0.20, y: 0.30),
            control1: CGPoint(x: 0.28, y: 0.35),
            control2: CGPoint(x: 0.22, y: 0.32)
        )
        
        // Casino Square
        path.addCurve(
            to: CGPoint(x: 0.30, y: 0.18),
            control1: CGPoint(x: 0.18, y: 0.28),
            control2: CGPoint(x: 0.25, y: 0.18)
        )
        
        // Mirabeau
        path.addCurve(
            to: CGPoint(x: 0.55, y: 0.22),
            control1: CGPoint(x: 0.35, y: 0.18),
            control2: CGPoint(x: 0.48, y: 0.20)
        )
        
        // Grand Hotel Hairpin (tightest corner in F1)
        path.addCurve(
            to: CGPoint(x: 0.58, y: 0.30),
            control1: CGPoint(x: 0.62, y: 0.24),
            control2: CGPoint(x: 0.62, y: 0.28)
        )
        
        // Portier
        path.addLine(to: CGPoint(x: 0.70, y: 0.35))
        
        // Tunnel section
        path.addCurve(
            to: CGPoint(x: 0.88, y: 0.45),
            control1: CGPoint(x: 0.78, y: 0.38),
            control2: CGPoint(x: 0.85, y: 0.42)
        )
        
        // Nouvelle Chicane
        path.addCurve(
            to: CGPoint(x: 0.82, y: 0.55),
            control1: CGPoint(x: 0.90, y: 0.50),
            control2: CGPoint(x: 0.86, y: 0.54)
        )
        
        // Tabac
        path.addCurve(
            to: CGPoint(x: 0.75, y: 0.70),
            control1: CGPoint(x: 0.78, y: 0.58),
            control2: CGPoint(x: 0.76, y: 0.65)
        )
        
        // Swimming Pool complex
        path.addCurve(
            to: CGPoint(x: 0.68, y: 0.82),
            control1: CGPoint(x: 0.74, y: 0.76),
            control2: CGPoint(x: 0.70, y: 0.80)
        )
        
        // Rascasse
        path.addCurve(
            to: CGPoint(x: 0.55, y: 0.88),
            control1: CGPoint(x: 0.66, y: 0.85),
            control2: CGPoint(x: 0.60, y: 0.88)
        )
        
        // Final corner
        path.addCurve(
            to: CGPoint(x: 0.5, y: 0.95),
            control1: CGPoint(x: 0.50, y: 0.88),
            control2: CGPoint(x: 0.48, y: 0.92)
        )
        
        path.closeSubpath()
        return path
    }
    
    /// Silverstone Circuit - Fast, flowing corners
    /// Characteristic: High-speed corners, Maggots-Becketts complex, old airfield
    static var silverstonePath: Path {
        var path = Path()
        
        // Start at main straight
        path.move(to: CGPoint(x: 0.25, y: 0.55))
        
        // Abbey and Farm curve
        path.addLine(to: CGPoint(x: 0.45, y: 0.55))
        path.addCurve(
            to: CGPoint(x: 0.55, y: 0.45),
            control1: CGPoint(x: 0.52, y: 0.52),
            control2: CGPoint(x: 0.55, y: 0.48)
        )
        
        // Village
        path.addCurve(
            to: CGPoint(x: 0.65, y: 0.42),
            control1: CGPoint(x: 0.58, y: 0.43),
            control2: CGPoint(x: 0.62, y: 0.42)
        )
        
        // The Loop
        path.addCurve(
            to: CGPoint(x: 0.72, y: 0.35),
            control1: CGPoint(x: 0.68, y: 0.42),
            control2: CGPoint(x: 0.72, y: 0.38)
        )
        
        // Aintree
        path.addCurve(
            to: CGPoint(x: 0.78, y: 0.28),
            control1: CGPoint(x: 0.72, y: 0.32),
            control2: CGPoint(x: 0.76, y: 0.28)
        )
        
        // Wellington Straight
        path.addLine(to: CGPoint(x: 0.55, y: 0.15))
        
        // Brooklands
        path.addCurve(
            to: CGPoint(x: 0.40, y: 0.20),
            control1: CGPoint(x: 0.50, y: 0.15),
            control2: CGPoint(x: 0.45, y: 0.17)
        )
        
        // Luffield
        path.addCurve(
            to: CGPoint(x: 0.30, y: 0.30),
            control1: CGPoint(x: 0.35, y: 0.23),
            control2: CGPoint(x: 0.30, y: 0.27)
        )
        
        // Woodcote
        path.addCurve(
            to: CGPoint(x: 0.25, y: 0.42),
            control1: CGPoint(x: 0.30, y: 0.33),
            control2: CGPoint(x: 0.25, y: 0.38)
        )
        
        // Copse
        path.addCurve(
            to: CGPoint(x: 0.25, y: 0.55),
            control1: CGPoint(x: 0.25, y: 0.46),
            control2: CGPoint(x: 0.22, y: 0.52)
        )
        
        path.closeSubpath()
        return path
    }
    
    /// Autodromo Nazionale Monza - Temple of Speed
    /// Characteristic: Long straights, low downforce, historic circuit
    static var monzaPath: Path {
        var path = Path()
        
        // Start at main straight (start/finish)
        path.move(to: CGPoint(x: 0.30, y: 0.50))
        
        // Main straight (long!)
        path.addLine(to: CGPoint(x: 0.75, y: 0.50))
        
        // Variante del Rettifilo (chicane)
        path.addCurve(
            to: CGPoint(x: 0.82, y: 0.38),
            control1: CGPoint(x: 0.80, y: 0.48),
            control2: CGPoint(x: 0.82, y: 0.42)
        )
        
        // Curva Grande
        path.addCurve(
            to: CGPoint(x: 0.72, y: 0.20),
            control1: CGPoint(x: 0.82, y: 0.32),
            control2: CGPoint(x: 0.78, y: 0.22)
        )
        
        // Variante della Roggia
        path.addCurve(
            to: CGPoint(x: 0.60, y: 0.15),
            control1: CGPoint(x: 0.68, y: 0.18),
            control2: CGPoint(x: 0.64, y: 0.15)
        )
        
        // Curva di Lesmo 1 & 2
        path.addCurve(
            to: CGPoint(x: 0.40, y: 0.18),
            control1: CGPoint(x: 0.55, y: 0.15),
            control2: CGPoint(x: 0.48, y: 0.16)
        )
        
        // Curva del Serraglio
        path.addLine(to: CGPoint(x: 0.25, y: 0.25))
        
        // Curva del Vialone
        path.addCurve(
            to: CGPoint(x: 0.18, y: 0.35),
            control1: CGPoint(x: 0.22, y: 0.28),
            control2: CGPoint(x: 0.18, y: 0.32)
        )
        
        // Variante dell'Ascari (chicane)
        path.addCurve(
            to: CGPoint(x: 0.22, y: 0.50),
            control1: CGPoint(x: 0.20, y: 0.40),
            control2: CGPoint(x: 0.20, y: 0.48)
        )
        
        // Curva Parabolica (legendary final corner)
        path.addCurve(
            to: CGPoint(x: 0.30, y: 0.50),
            control1: CGPoint(x: 0.24, y: 0.52),
            control2: CGPoint(x: 0.27, y: 0.52)
        )
        
        path.closeSubpath()
        return path
    }
    
    /// Suzuka International Racing Course - Figure-8 layout
    /// Characteristic: Unique crossover, technical, Spoon curve, 130R
    static var suzukaPath: Path {
        var path = Path()
        
        // Start at main straight
        path.move(to: CGPoint(x: 0.20, y: 0.60))
        
        // First corner complex
        path.addLine(to: CGPoint(x: 0.45, y: 0.60))
        
        // Turns 1-2 (First Curve)
        path.addCurve(
            to: CGPoint(x: 0.55, y: 0.50),
            control1: CGPoint(x: 0.52, y: 0.58),
            control2: CGPoint(x: 0.55, y: 0.54)
        )
        
        // S Curves (turns 3-6)
        path.addCurve(
            to: CGPoint(x: 0.50, y: 0.35),
            control1: CGPoint(x: 0.58, y: 0.45),
            control2: CGPoint(x: 0.55, y: 0.38)
        )
        
        path.addCurve(
            to: CGPoint(x: 0.58, y: 0.25),
            control1: CGPoint(x: 0.45, y: 0.32),
            control2: CGPoint(x: 0.52, y: 0.25)
        )
        
        // Degner Curve
        path.addCurve(
            to: CGPoint(x: 0.72, y: 0.30),
            control1: CGPoint(x: 0.64, y: 0.25),
            control2: CGPoint(x: 0.68, y: 0.27)
        )
        
        // Under crossover bridge
        path.addLine(to: CGPoint(x: 0.78, y: 0.42))
        
        // Hairpin
        path.addCurve(
            to: CGPoint(x: 0.65, y: 0.55),
            control1: CGPoint(x: 0.82, y: 0.48),
            control2: CGPoint(x: 0.75, y: 0.55)
        )
        
        // Spoon Curve (iconic)
        path.addCurve(
            to: CGPoint(x: 0.55, y: 0.75),
            control1: CGPoint(x: 0.58, y: 0.58),
            control2: CGPoint(x: 0.52, y: 0.70)
        )
        
        // 130R (legendary high-speed corner)
        path.addCurve(
            to: CGPoint(x: 0.40, y: 0.82),
            control1: CGPoint(x: 0.50, y: 0.80),
            control2: CGPoint(x: 0.45, y: 0.82)
        )
        
        // Casino Triangle (chicane)
        path.addCurve(
            to: CGPoint(x: 0.25, y: 0.75),
            control1: CGPoint(x: 0.35, y: 0.82),
            control2: CGPoint(x: 0.28, y: 0.80)
        )
        
        // Final section - crossover over the bridge
        path.addCurve(
            to: CGPoint(x: 0.20, y: 0.60),
            control1: CGPoint(x: 0.22, y: 0.70),
            control2: CGPoint(x: 0.18, y: 0.65)
        )
        
        path.closeSubpath()
        return path
    }
    
    /// Default fallback path (generic oval)
    static var defaultPath: Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0.20, y: 0.50))
        path.addLine(to: CGPoint(x: 0.80, y: 0.50))
        path.addCurve(
            to: CGPoint(x: 0.80, y: 0.50),
            control1: CGPoint(x: 0.85, y: 0.30),
            control2: CGPoint(x: 0.85, y: 0.70)
        )
        path.addLine(to: CGPoint(x: 0.20, y: 0.50))
        path.addCurve(
            to: CGPoint(x: 0.20, y: 0.50),
            control1: CGPoint(x: 0.15, y: 0.70),
            control2: CGPoint(x: 0.15, y: 0.30)
        )
        
        return path
    }
}

// MARK: - Shape Convenience

/// A SwiftUI Shape that wraps a circuit path
struct CircuitShape: Shape {
    let circuitId: String
    
    func path(in rect: CGRect) -> Path {
        let path = CircuitPaths.path(for: circuitId)
        
        // Scale the normalized path (0-1) to the actual rect size
        var scaledPath = Path()
        
        path.forEach { element in
            switch element {
            case .move(let to):
                scaledPath.move(to: CGPoint(
                    x: to.x * rect.width + rect.minX,
                    y: to.y * rect.height + rect.minY
                ))
            case .line(let to):
                scaledPath.addLine(to: CGPoint(
                    x: to.x * rect.width + rect.minX,
                    y: to.y * rect.height + rect.minY
                ))
            case .curve(let to, let control1, let control2):
                scaledPath.addCurve(
                    to: CGPoint(
                        x: to.x * rect.width + rect.minX,
                        y: to.y * rect.height + rect.minY
                    ),
                    control1: CGPoint(
                        x: control1.x * rect.width + rect.minX,
                        y: control1.y * rect.height + rect.minY
                    ),
                    control2: CGPoint(
                        x: control2.x * rect.width + rect.minX,
                        y: control2.y * rect.height + rect.minY
                    )
                )
            case .quadCurve(let to, let control):
                scaledPath.addQuadCurve(
                    to: CGPoint(
                        x: to.x * rect.width + rect.minX,
                        y: to.y * rect.height + rect.minY
                    ),
                    control: CGPoint(
                        x: control.x * rect.width + rect.minX,
                        y: control.y * rect.height + rect.minY
                    )
                )
            case .closeSubpath:
                scaledPath.closeSubpath()
            @unknown default:
                break
            }
        }
        
        return scaledPath
    }
}
