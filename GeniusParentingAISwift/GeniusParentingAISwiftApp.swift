import SwiftUI
import KeychainAccess

@main
struct GeniusParentingAISwiftApp: App {
    @State private var isLoggedIn = false // Track login state
    
    // REVISED: Create one shared instance of SpeechManager for the entire app.
    @StateObject private var speechManager = SpeechManager()

    private let keychain = Keychain(service: Config.keychainService)

    init() {
        // This will print the Strapi URL to the console on app launch.
        print("Application is connecting to Strapi Server at: \(Config.strapiBaseUrl)")
    }
    
    var body: some Scene {
        WindowGroup {
            // The Group allows us to apply the modifier to the entire conditional content.
            Group {
                if isLoggedIn {
                    MainView(isLoggedIn: $isLoggedIn)
                } else {
                    LoginView(isLoggedIn: $isLoggedIn)
                }
            }
            // REVISED: Inject the shared SpeechManager into the SwiftUI environment.
            .environmentObject(speechManager)
        }
    }
}
