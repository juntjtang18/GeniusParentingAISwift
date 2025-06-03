import SwiftUI
import KeychainAccess

@main
struct GeniusParentingAISwiftApp: App {
    @State private var isLoggedIn = false // Track login state
    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

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
