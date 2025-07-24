// GeniusParentingAISwiftApp.swift

import SwiftUI
import KeychainAccess

// MARK: - Session Manager
@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var currentUser: StrapiUser?
    /// Computes the user's role based on their subscription plan.
    var role: Role {
        // Safely access the role string from the user's subscribed plan.
        guard let roleString = currentUser?.subscription?.data?.attributes.plan.attributes.role else {
            // If there's no plan or role string, default to 'free'.
            return .free
        }
        
        // Initialize our Role enum from the string. If the string from the backend
        // doesn't match a case in our enum, default to 'free'.
        return Role(rawValue: roleString) ?? .free
    }

    private init() {}
}


@main
struct GeniusParentingAISwiftApp: App {
    @State private var isLoggedIn = false
    @State private var isCheckingToken = true
    
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var themeManager = ThemeManager()

    private let keychain = Keychain(service: Config.keychainService)

    init() {
        print("Application is connecting to Strapi Server at: \(Config.strapiBaseUrl)")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isCheckingToken {
                    ProgressView("Checking Login Status...")
                } else if isLoggedIn {
                    MainView(isLoggedIn: $isLoggedIn)
                } else {
                    LoginView(isLoggedIn: $isLoggedIn)
                }
            }
            .environmentObject(speechManager)
            .theme(themeManager.currentTheme)
            .environmentObject(themeManager)
            .onAppear(perform: checkLoginStatus)
            .onReceive(NotificationCenter.default.publisher(for: .didInvalidateSession)) { _ in
                isLoggedIn = false
            }
        }
    }

    private func checkLoginStatus() {
        Task {
            // Check if a JWT token exists in the keychain.
            if keychain["jwt"] != nil {
                do {
                    // Attempt to fetch the current user's profile using the token.
                    let user = try await StrapiService.shared.fetchCurrentUser()
                    
                    // If successful, update the session and set the logged-in state to true.
                    SessionManager.shared.currentUser = user
                    isLoggedIn = true
                } catch {
                    // If the fetch fails (e.g., token is expired), clear the invalid token
                    // and ensure the logged-in state is false.
                    keychain["jwt"] = nil
                    isLoggedIn = false
                }
            } else {
                // If no token is found, the user is not logged in.
                isLoggedIn = false
            }
            
            // Hide the loading indicator once the check is complete.
            isCheckingToken = false
        }
    }
}
