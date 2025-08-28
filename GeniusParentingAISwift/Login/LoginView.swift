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
                    //theme.background.ignoresSafeArea()
                    LinearGradient(
                        colors: [theme.background, theme.background2],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    VStack(spacing: 20) {
                        Image("applogo-\(theme.id)")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .padding(.bottom, 20)

                        // Email
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(theme.inputBoxForeground.opacity(0.6)))
                            .font(.system(size: 20))
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 18)
                            .frame(height: 50)
                            .background(theme.inputBoxBackground)
                            //.foregroundColor(theme.inputBoxForeground)         // text color
                            .overlay(
                                Capsule().stroke(theme.border, lineWidth: 2) // subtle hairline
                            )
                            .clipShape(Capsule())
                            .padding(.horizontal)
                            .disabled(isLoading)

                        // Password
                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(theme.inputBoxForeground.opacity(0.6)))
                            .font(.system(size: 20))
                            .autocapitalization(.none)
                            .padding(.horizontal, 18)
                            .frame(height: 50)
                            .background(theme.inputBoxBackground)
                            //.foregroundColor(theme.inputBoxForeground)
                            .overlay(
                                Capsule().stroke(theme.border, lineWidth: 2)
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
                                            .foregroundColor(theme.accentThird)
                                    }
                                    .buttonStyle(.plain)

                                    Text("Terms of Service")
                                        .font(.caption)
                                        .foregroundColor(theme.accentThird)
                                        .onTapGesture { showingTermsOfService = true }
                                }

                                // Privacy row
                                HStack(spacing: 8) {
                                    Button { agreeToPrivacy.toggle() } label: {
                                        Image(systemName: agreeToPrivacy ? "checkmark.square.fill" : "square")
                                            .foregroundColor(theme.accentThird)
                                    }
                                    .buttonStyle(.plain)

                                    Text("Privacy Policy")
                                        .font(.caption)
                                        .foregroundColor(theme.accentThird)
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
                                    .background(theme.primary)
                                    .foregroundColor(theme.primaryText)
                                    .overlay(
                                        Capsule().stroke(theme.border, lineWidth: 2)   // ⬅️ added border
                                    )
                                    .clipShape(Capsule())
                            }
                            .disabled(isLoading || !agreeToTerms || !agreeToPrivacy)
                        }
                        .padding(.horizontal)
                        
                        Button(action: { currentView = .signup }) {
                            Text("Don't have an account? Sign Up")
                                .foregroundColor(theme.accentThird)
                                .backgroundStyle(theme.accentBackground)
                        }
                        .padding()
                    }
                    .padding()
                }
                .toolbarBackground(
                    LinearGradient(colors: [theme.background2, theme.background],
                                   startPoint: .top, endPoint: .bottom),
                    for: .navigationBar
                )
                .toolbarBackground(.visible, for: .navigationBar)
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
