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

    // ✅ Persist the app-level language (default to English)
    // Use identifiers that match your Localizable.xcstrings (e.g., "en", "zh-Hans")
    //@AppStorage("appLanguage") private var appLanguage: String = "zh_CN"

    init() {
        print("Application is connecting to Strapi Server at: \(Config.strapiBaseUrl)")
    }
    
    var body: some Scene {
        WindowGroup {
            DimensionsProvider {
                ZStack {
                    if isCheckingToken {
                        // This will localize according to .environment(\.locale, ...)
                        ProgressView(String(localized: "Checking Login Status..."))
                    } else if isLoggedIn, let user = SessionManager.shared.currentUser {
                        MainView(isLoggedIn: $isLoggedIn, logoutAction: { SessionManager.shared.logout() })
                            .id(user.id)
                    } else {
                        LoginView(isLoggedIn: $isLoggedIn)
                    }
                }
                // App-wide dependencies
                .environmentObject(speechManager)
                .environmentObject(themeManager)
                .environmentObject(storeManager)
                .environmentObject(permissionManager)

                // ✅ Apply the selected language globally (one line to rule them all)
                //.environment(\.locale, Locale(identifier: appLanguage))

                .theme(themeManager.currentTheme)
                .onAppear {
                    // Compute an effective locale that actually exists in the bundle
                    //let available = Set(Bundle.main.localizations.map { $0 }) // e.g. ["Base", "zh_CN", "en"]
                    //let preferredDefault = Bundle.main.preferredLocalizations.first ?? "en"

                    // If the selected appLanguage isn't shipped, fall back to preferredDefault (or "zh_CN" if that’s your real default)
                    //let effectiveLanguage = available.contains(appLanguage) ? appLanguage : preferredDefault

                    // Optional debug
                    //print("AppStorage appLanguage=\(appLanguage), available=\(available), effective=\(effectiveLanguage)")

                    checkLoginStatus()
                    //let defaultLocale = Locale.current.identifier
                    //print("System locale before override: \(defaultLocale)")

                    // ✅ Verify the appStorage language override
                    //print("AppStorage locale override (appLanguage): \(appLanguage)")

                    // Optional: check what Locale() would resolve to in SwiftUI environment
                    //let activeLocale = Locale(identifier: appLanguage)
                    //print("Effective Locale identifier used by .environment(\\.locale): \(activeLocale.identifier)")

                }
                // ✅ Listen for our custom logout notification
                .onReceive(NotificationCenter.default.publisher(for: .didLogout)) { _ in
                    handleLogout()
                }
                // Listen for session invalidation (e.g., from NetworkManager)
                .onReceive(NotificationCenter.default.publisher(for: .didInvalidateSession)) { _ in
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
                SessionManager.shared.startSession(jwt: SessionManager.shared.getJWT()!, user: user)
                isLoggedIn = true
            } catch {
                SessionManager.shared.clearSession()
                isLoggedIn = false
            }
        }
    }

    /// Updates only UI state on logout
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .ignoresSafeArea()
        }
    }
}
