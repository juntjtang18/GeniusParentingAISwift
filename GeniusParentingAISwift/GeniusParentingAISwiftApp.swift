import SwiftUI
import KeychainAccess
import StoreKit

extension Notification.Name {
    static let didLogout = Notification.Name("didLogout")
}

@main
struct GeniusParentingAISwiftApp: App {
    @State private var isLoggedIn = false
    @State private var isCheckingToken = true
    
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var storeManager = StoreManager.shared

    init() {
        print("Application is connecting to Strapi Server at: \(Config.strapiBaseUrl)")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isCheckingToken {
                    ProgressView("Checking Login Status...")
                } else if isLoggedIn, let user = SessionManager.shared.currentUser {
                    MainView(isLoggedIn: $isLoggedIn, logoutAction: logout)
                        .id(user.id)
                } else {
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

    private func checkLoginStatus() {
        Task {
            if let jwt = SessionManager.shared.getJWT() {
                do {
                    let user = try await StrapiService.shared.fetchCurrentUser()
                    SessionManager.shared.currentUser = user
                    SessionManager.shared.updateLastUserEmail(user.email)
                    await storeManager.updatePurchasedProducts()
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
        SessionManager.shared.clearSession()
        NotificationCenter.default.post(name: .didLogout, object: nil)
        withAnimation {
            isLoggedIn = false
        }
    }
}
