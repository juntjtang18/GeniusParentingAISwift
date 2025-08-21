// GeniusParentingAISwiftApp.swift

import SwiftUI
import KeychainAccess
import StoreKit

extension Notification.Name {
    static let didLogout = Notification.Name("didLogout")
}

/// Everything you might want globally.
struct AppDimensions: Equatable {
    var screenSize: CGSize         // logical points
    var safeArea: EdgeInsets
    var displayScale: CGFloat
}

private struct AppDimensionsKey: EnvironmentKey {
    static let defaultValue = AppDimensions(
        screenSize: UIScreen.main.bounds.size,
        safeArea: .init(),
        displayScale: UIScreen.main.scale
    )
}

extension EnvironmentValues {
    var appDimensions: AppDimensions {
        get { self[AppDimensionsKey.self] }
        set { self[AppDimensionsKey.self] = newValue }
    }
}

/// Provide dimensions once at the app root. This is the ONLY place we use GeometryReader.
private struct DimensionsProvider<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let dims = AppDimensions(
                screenSize: proxy.size,
                safeArea: proxy.safeAreaInsets,
                displayScale: UIScreen.main.scale
            )
            content()
                .environment(\.appDimensions, dims)
                // Keep your existing safe-area behavior as-is at call-sites.
        }
    }
}

@main
struct GeniusParentingAISwiftApp: App {
    @State private var isLoggedIn = false
    @State private var isCheckingToken = true
    
    // This uses UserDefaults to store a boolean.
    // The key in UserDefaults will be "hasCompletedPersonalityTest".
    @AppStorage("hasCompletedPersonalityTest") private var hasCompletedPersonalityTest = false
    
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var storeManager = StoreManager.shared

    init() {
        print("Application is connecting to Strapi Server at: \(Config.strapiBaseUrl)")
    }
    
    var body: some Scene {
        WindowGroup {
            DimensionsProvider {
                ZStack {
                    if isCheckingToken {
                        ProgressView("Checking Login Status...")
                    } else if isLoggedIn, let user = SessionManager.shared.currentUser {
                        // Step 1: Always have MainView ready for a logged-in user.
                        MainView(isLoggedIn: $isLoggedIn, logoutAction: logout)
                            .id(user.id)
                            // Step 2: Present the onboarding flow as a modal cover.
                            .fullScreenCover(isPresented: $hasCompletedPersonalityTest.inverted) {
                                // This is the view that will be presented.
                                // It uses the same binding to dismiss itself when done.
                                OnboardingFlowView(didComplete: $hasCompletedPersonalityTest)
                            }
                        
                        // --- END: NEW MODAL LOGIC ---

                    } else {
                        // If not logged in, show the login view.
                        LoginView(isLoggedIn: $isLoggedIn)
                    }
                }
                .environmentObject(speechManager)
                .environmentObject(themeManager)
                .environmentObject(storeManager)
                .theme(themeManager.currentTheme)
                .onAppear {
                    PermissionManager.shared.storeManager = storeManager
                    checkLoginStatus()
                }
                .onReceive(NotificationCenter.default.publisher(for: .didInvalidateSession)) { _ in
                    logout()
                }
            }
        }
    }

    private func checkLoginStatus() {
        Task {
            if let jwt = SessionManager.shared.getJWT() {
                do {
                    let user = try await StrapiService.shared.fetchCurrentUser()
                    SessionManager.shared.setCurrentUser(user)
                    SessionManager.shared.updateLastUserEmail(user.email)
                    isLoggedIn = true
                } catch {
                    SessionManager.shared.clearSession()
                    isLoggedIn = false
                }
            } else {
                SessionManager.shared.clearSession()
                isLoggedIn = false
            }
            isCheckingToken = false
        }
    }

    private func logout() {
        // This function is correct, no changes needed.
        SessionManager.shared.clearSession()
        //hasCompletedPersonalityTest = false // It's good practice to reset this on logout
        NotificationCenter.default.post(name: .didLogout, object: nil)
        withAnimation {
            isLoggedIn = false
        }
    }
}
extension Binding where Value == Bool {
    var inverted: Binding<Bool> {
        Binding<Bool>(
            get: { !self.wrappedValue },
            set: { self.wrappedValue = !$0 }
        )
    }
}
