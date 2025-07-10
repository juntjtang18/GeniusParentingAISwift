import SwiftUI

protocol Theme {
    var id: String { get }
    var primary: Color { get }
    var secondary: Color { get }
    var accent: Color { get }
    var background: Color { get }
    var text: Color { get }
}

struct OceanBreezeTheme: Theme {
    let id: String = "OceanBreeze"
    // ✅ Corrected asset names to match the script's output
    let primary = Color("ColorSchemes/OceanBreeze/OceanBreezePrimary")
    let secondary = Color("ColorSchemes/OceanBreeze/OceanBreezeSecondary")
    let accent = Color("ColorSchemes/OceanBreeze/OceanBreezeAccent")
    let background = Color("ColorSchemes/OceanBreeze/OceanBreezeBackground")
    let text = Color("ColorSchemes/OceanBreeze/OceanBreezeText")
}

struct SunsetCoralTheme: Theme {
    let id: String = "SunsetCoral"
    let primary = Color("ColorSchemes/SunsetCoral/SunsetCoralPrimary")
    let secondary = Color("ColorSchemes/SunsetCoral/SunsetCoralSecondary")
    let accent = Color("ColorSchemes/SunsetCoral/SunsetCoralAccent")
    let background = Color("ColorSchemes/SunsetCoral/SunsetCoralBackground")
    let text = Color("ColorSchemes/SunsetCoral/SunsetCoralText")
}

struct ForestNightTheme: Theme {
    let id: String = "ForestNight"
    let primary = Color("ColorSchemes/ForestNight/ForestNightPrimary")
    let secondary = Color("ColorSchemes/ForestNight/ForestNightSecondary")
    let accent = Color("ColorSchemes/ForestNight/ForestNightAccent")
    let background = Color("ColorSchemes/ForestNight/ForestNightBackground")
    let text = Color("ColorSchemes/ForestNight/ForestNightText")
}

struct SoftPastelTheme: Theme {
    let id: String = "SoftPastel"
    let primary = Color("ColorSchemes/SoftPastel/SoftPastelPrimary")
    let secondary = Color("ColorSchemes/SoftPastel/SoftPastelSecondary")
    let accent = Color("ColorSchemes/SoftPastel/SoftPastelAccent")
    let background = Color("ColorSchemes/SoftPastel/SoftPastelBackground")
    let text = Color("ColorSchemes/SoftPastel/SoftPastelText")
}
