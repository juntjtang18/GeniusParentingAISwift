import SwiftUI

class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = OceanBreezeTheme()
    
    let themes: [Theme] = [
        OceanBreezeTheme(),
        SunsetCoralTheme(),
        ForestNightTheme(),
        SoftPastelTheme()
    ]

    init() {
        // ✅ LOG 1: Confirm the ThemeManager is created and themes are loaded.
        print("LOG: ThemeManager initialized with \(themes.count) themes.")
        
        let savedThemeID = UserDefaults.standard.string(forKey: "selectedThemeID") ?? "OceanBreeze"
        setTheme(id: savedThemeID)
    }

    func setTheme(id: String) {
        if let selectedTheme = themes.first(where: { $0.id == id }) {
            self.currentTheme = selectedTheme
            UserDefaults.standard.set(selectedTheme.id, forKey: "selectedThemeID")
        }
    }
}
