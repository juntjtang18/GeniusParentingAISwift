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
                            .foregroundColor(theme.text)

                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding(.horizontal)
                            .disabled(isLoading)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .disabled(isLoading)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(theme.accent)
                                .padding()
                        }
                        
                        if isLoading {
                            ProgressView()
                                .padding()
                        }
                        
                        VStack(spacing: 15) {
                            VStack(alignment: .leading, spacing: 10) {
                                Button(action: { agreeToTerms.toggle() }) {
                                    HStack {
                                        Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                            .foregroundColor(theme.accent)
                                        Text("I agree to the")
                                        Button("Terms of Service") {
                                            showingTermsOfService = true
                                        }
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(theme.text)
                                .sheet(isPresented: $showingTermsOfService) {
                                    TermsOfServiceView(isPresented: $showingTermsOfService)
                                }
                                
                                Button(action: { agreeToPrivacy.toggle() }) {
                                    HStack {
                                        Image(systemName: agreeToPrivacy ? "checkmark.square.fill" : "square")
                                            .foregroundColor(theme.accent)
                                        Text("I agree to the")
                                        Button("Privacy Policy") {
                                            showingPrivacyPolicy = true
                                        }
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(theme.text)
                                .sheet(isPresented: $showingPrivacyPolicy) {
                                    PrivacyPolicyView(isPresented: $showingPrivacyPolicy)
                                }
                            }
                            
                            Button(action: {
                                Task {
                                    await login()
                                }
                            }) {
                                Text("Login")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isLoading || !agreeToTerms || !agreeToPrivacy ? Color(.systemGray4) : theme.accent)
                                    .foregroundColor((isLoading || !agreeToTerms || !agreeToPrivacy) ? theme.text.opacity(0.6) : .white)
                                    .clipShape(Capsule())
                            }
                            .disabled(isLoading || !agreeToTerms || !agreeToPrivacy)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            currentView = .signup
                        }) {
                            Text("Don't have an account? Sign Up")
                        }
                        .buttonStyle(LinkStyleButtonStyle())
                        .padding()
                    }
                    .padding()
                }
                .textFieldStyle(ThemedTextFieldStyle())
            } else if currentView == .signup {
                SignupView(isLoggedIn: $isLoggedIn, currentView: $currentView)
            }
        }
    }

    func login() async {
        isLoading = true
        errorMessage = ""
        print("Login attempt for email: \(email)")
        
        let credentials = LoginCredentials(identifier: email, password: password)
        
        do {
            // A fresh login should always perform a new login to get the latest user data.
            print("Performing new login")
            SessionManager.shared.clearSession()
            try await performNewLogin(credentials: credentials)
        } catch {
            print("Login failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            SessionManager.shared.clearSession()
            isLoggedIn = false
        }
        
        isLoading = false
    }

    private func performNewLogin(credentials: LoginCredentials) async throws {
        print("Performing new login for \(credentials.identifier)")
        let authResponse = try await StrapiService.shared.login(credentials: credentials)
        print("Login successful, JWT: \(authResponse.jwt)")
        SessionManager.shared.setJWT(authResponse.jwt)
        SessionManager.shared.setCurrentUser(authResponse.user)
        SessionManager.shared.updateLastUserEmail(authResponse.user.email)
        
        // **CRITICAL FIX:** Sync the store with the server's subscription data.
        //StoreManager.shared.syncWithServerState(for: authResponse.user)
        
        isLoggedIn = true
    }
}
