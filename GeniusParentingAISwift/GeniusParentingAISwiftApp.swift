import SwiftUI
import KeychainAccess

@main
struct GeniusParentingAISwiftApp: App {
    @State private var isLoggedIn = false
    @State private var isCheckingToken = true
    
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
            ZStack {
                if isCheckingToken {
                    ProgressView("Checking Login Status...")
                } else if isLoggedIn {
                    MainView(isLoggedIn: $isLoggedIn)
                } else {
                    LoginView(isLoggedIn: $isLoggedIn)
                }
            }
            // REVISED: Inject the shared SpeechManager into the SwiftUI environment.
            .environmentObject(speechManager)
            .onAppear(perform: checkLoginStatus)
        }
    }

    private func checkLoginStatus() {
        Task {
            // FIXED: Changed from 'if let' to a boolean check to resolve the warning.
            if keychain["jwt"] != nil {
                do {
                    // Attempt to fetch the user to validate the token
                    _ = try await NetworkManager.shared.fetchUser()
                    isLoggedIn = true
                } catch {
                    // If fetch fails, the token is likely invalid or expired
                    keychain["jwt"] = nil
                    isLoggedIn = false
                }
            } else {
                isLoggedIn = false
            }
            isCheckingToken = false
        }
    }
}
