// GeniusParentingAISwiftApp.swift

import SwiftUI
import KeychainAccess
import StoreKit

@main
struct GeniusParentingAISwiftApp: App {
    @State private var isLoggedIn = false
    @State private var isCheckingToken = true
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var storeManager = StoreManager.shared
    @StateObject private var permissionManager = PermissionManager.shared

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
                        // The logoutAction now calls the centralized SessionManager.logout()
                        MainView(isLoggedIn: $isLoggedIn, logoutAction: { SessionManager.shared.logout() })
                            .id(user.id)
                    } else {
                        LoginView(isLoggedIn: $isLoggedIn)
                    }
                }
                .environmentObject(speechManager)
                .environmentObject(themeManager)
                .environmentObject(storeManager)
                .environmentObject(permissionManager)
                .theme(themeManager.currentTheme)
                .onAppear {
                    checkLoginStatus()
                }
                // ✅ ADDED: Listen for our custom logout notification
                .onReceive(NotificationCenter.default.publisher(for: .didLogout)) { _ in
                    handleLogout()
                }
                // Listen for session invalidation (e.g., from NetworkManager)
                .onReceive(NotificationCenter.default.publisher(for: .didInvalidateSession)) { _ in
                    // We can call logout directly here as well to ensure data is cleared
                    SessionManager.shared.logout()
                }
            }
        }
    }

    private func checkLoginStatus() {
        Task {
            defer { isCheckingToken = false }

            guard SessionManager.shared.getJWT() != nil else {
                SessionManager.shared.clearSession()
                isLoggedIn = false
                return
            }
            do {
                let user = try await StrapiService.shared.fetchCurrentUser()
                // Use the new convenience method to set up the session
                SessionManager.shared.startSession(jwt: SessionManager.shared.getJWT()!, user: user)
                isLoggedIn = true
            } catch {
                SessionManager.shared.clearSession()
                isLoggedIn = false
            }
        }
    }


    /// ✅ REFACTORED: This function's only job is to update the UI state.
    private func handleLogout() {
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


extension Notification.Name {
    static let didLogout = Notification.Name("didLogout")
}

/// Everything you might want globally.
struct AppDimensions: Equatable {
    var screenSize: CGSize      // logical points
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
                // ⬇️ ensure the wrapped content (your ZStack) fills the screen
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .ignoresSafeArea() // optional: match your existing safe-area behavior
        }
    }
}
