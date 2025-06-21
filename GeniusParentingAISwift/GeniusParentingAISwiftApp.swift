import SwiftUI
import KeychainAccess

@main
struct GeniusParentingAISwiftApp: App {
    @State private var isLoggedIn = false // Track login state
    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")
    init() {
        // This will print the Strapi URL to the console on app launch.
        print("🚀 Application is connecting to Strapi Server at: \(Config.strapiBaseUrl)")
    }
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainView(isLoggedIn: $isLoggedIn)
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
