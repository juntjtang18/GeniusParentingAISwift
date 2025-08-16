// GeniusParentingAISwift/LoginView.swift

import SwiftUI
import KeychainAccess

struct LoginView: View {
    @Environment(\.theme) var theme: Theme
    @Binding var isLoggedIn: Bool
    @State private var currentView: ViewState = .login
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var agreeToTerms = false
    @State private var agreeToPrivacy = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    private let inputInset: CGFloat = 50   // match TextField/SecureField horizontal padding

    enum ViewState {
        case login
        case signup
    }

    var body: some View {
        Group {
            if currentView == .login {
                ZStack {
                    theme.background.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("Welcome to Genius Parenting AI")
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Email
                        TextField("Email", text: $email)
                            .font(.system(size: 20))
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 18)
                            .frame(height: 50)
                            .background(theme.inputBoxBackground)
                            .foregroundColor(theme.foreground)         // text color
                            //.overlay(
                            //    Capsule().stroke(theme.border.opacity(0.15), lineWidth: 1) // subtle hairline
                            //)
                            .clipShape(Capsule())
                            .padding(.horizontal)
                            .disabled(isLoading)

                        // Password
                        SecureField("Password", text: $password)
                            .font(.system(size: 20))
                            .autocapitalization(.none)
                            .padding(.horizontal, 18)
                            .frame(height: 50)
                            .background(theme.inputBoxBackground)
                            .foregroundColor(theme.foreground)
                            .overlay(
                                Capsule().stroke(theme.border.opacity(0.15), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                            .padding(.horizontal)
                            .disabled(isLoading)
                        
                        
                        // The rest of the view remains the same...
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        if isLoading {
                            ProgressView()
                                .padding()
                        }
                        
                        VStack(spacing: 15) {
                            // ⬇︎ Checkbox block
                            VStack(alignment: .leading, spacing: 10) {
                                // Terms row
                                HStack(spacing: 8) {
                                    Button { agreeToTerms.toggle() } label: {
                                        Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                            .foregroundColor(theme.accent)
                                    }
                                    .buttonStyle(.plain)

                                    Text("Terms of Service")
                                        .font(.caption)
                                        .foregroundColor(theme.accent)
                                        .onTapGesture { showingTermsOfService = true }
                                }

                                // Privacy row
                                HStack(spacing: 8) {
                                    Button { agreeToPrivacy.toggle() } label: {
                                        Image(systemName: agreeToPrivacy ? "checkmark.square.fill" : "square")
                                            .foregroundColor(theme.accent)
                                    }
                                    .buttonStyle(.plain)

                                    Text("Privacy Policy")
                                        .font(.caption)
                                        .foregroundColor(theme.accent)
                                        .onTapGesture { showingPrivacyPolicy = true }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading) // expand to same width as button/fields
                            .padding(.leading, inputInset)
                            
                            Button(action: { Task { await login() } }) {
                                Text("Login")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(theme.accent)
                                    .foregroundColor(theme.background)
                                    .clipShape(Capsule())
                            }
                            .disabled(isLoading || !agreeToTerms || !agreeToPrivacy)
                        }
                        .padding(.horizontal)
                        
                        Button(action: { currentView = .signup }) {
                            Text("Don't have an account? Sign Up")
                                .foregroundColor(theme.accent)
                        }
                        .padding()
                    }
                    .padding()
                }
            } else if currentView == .signup {
                SignupView(isLoggedIn: $isLoggedIn, currentView: $currentView)
            }
        }
    }

    // login() and performNewLogin() functions remain the same...
    func login() async {
        isLoading = true
        errorMessage = ""
        let credentials = LoginCredentials(identifier: email, password: password)
        
        do {
            SessionManager.shared.clearSession()
            try await performNewLogin(credentials: credentials)
        } catch {
            errorMessage = error.localizedDescription
            SessionManager.shared.clearSession()
            isLoggedIn = false
        }
        
        isLoading = false
    }

    private func performNewLogin(credentials: LoginCredentials) async throws {
        let authResponse = try await StrapiService.shared.login(credentials: credentials)
        SessionManager.shared.setJWT(authResponse.jwt)
        SessionManager.shared.setCurrentUser(authResponse.user)
        SessionManager.shared.updateLastUserEmail(authResponse.user.email)
        isLoggedIn = true
    }
}
