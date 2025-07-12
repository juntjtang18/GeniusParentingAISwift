// GeniusParentingAISwiftApp.swift

import SwiftUI
import KeychainAccess

// MARK: - Session Manager
@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var currentUser: StrapiUser?

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
            // --- FIX: LISTEN FOR THE GLOBAL NOTIFICATION ---
            .onReceive(NotificationCenter.default.publisher(for: .didInvalidateSession)) { _ in
                // When the notification is received, force a logout.
                isLoggedIn = false
            }
        }
    }

    private func checkLoginStatus() {
        Task {
            if keychain["jwt"] != nil {
                do {
                    let user = try await StrapiService.shared.fetchCurrentUser()
                    SessionManager.shared.currentUser = user
                    isLoggedIn = true
                } catch {
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
