import SwiftUI

// 1) Protocol
protocol Theme {
    var id: String { get }

    // Updated color roles
    var foreground: Color { get }
    var background: Color { get }
    var accent: Color { get }
    var border: Color { get }
    var inputBoxBackground: Color { get }
    
    // NEW colors from the script
    var accentBackground: Color { get }
    var accentSecond: Color { get }
    var primary: Color { get }
    var primaryText: Color { get }
}

// 2) Concrete theme
struct AppTheme: Theme {
    let id: String

    init(id: String) { self.id = id }

    // Properties now match the Python script's definitions
    var foreground: Color         { color(for: "Foreground") }
    var background: Color         { color(for: "Background") }
    var accent: Color             { color(for: "Accent") }
    var border: Color             { color(for: "Border") }
    var inputBoxBackground: Color { color(for: "InputBoxBackground") }

    // NEW properties
    var accentBackground: Color   { color(for: "AccentBackground") }
    var accentSecond: Color       { color(for: "AccentSecond") }
    
    // FIXED: Changed "Primary" to "primary" to match the Python script's key.
    var primary: Color            { color(for: "Primary") }
    var primaryText: Color        { color(for: "PrimaryText") }
    
    private func color(for role: String) -> Color {
        // This correctly creates the full path for the namespaced asset,
        // for example: "ColorSchemes/WarmPurple/WarmPurpleprimary"
        Color("ColorSchemes/\(id)/\(id)\(role)")
    }
}
