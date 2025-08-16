import SwiftUI

// 1) Protocol
protocol Theme {
    var id: String { get }

    var foreground: Color { get }     // for text
    var background: Color { get }     // for background
    var accent: Color { get }         // for interactive controls
    var border: Color { get }         // for borders

    var primary: Color { get }
    var secondary: Color { get }
    var cardBackground: Color { get }

    // NEW
    var inputBoxBackground: Color { get }
}

// 2) Concrete theme
struct AppTheme: Theme {
    let id: String
    private let assetPath = "ColorSchemes/"

    init(id: String) { self.id = id }

    var foreground: Color      { color(for: "foreground") }
    var background: Color      { color(for: "Background") }
    var accent: Color          { color(for: "Accent") }
    var border: Color          { color(for: "border") }

    var primary: Color         { color(for: "Primary") }
    var secondary: Color       { color(for: "Secondary") }
    var cardBackground: Color  { color(for: "CardBackground") }

    // NEW
    var inputBoxBackground: Color { color(for: "InputBoxBackground") }

    private func color(for role: String) -> Color {
        // -> "ColorSchemes/<ThemeID>/<ThemeID><Role>"
        Color("\(assetPath)\(id)/\(id)\(role)")
    }
}
