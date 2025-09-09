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

    enum ViewState {
        case login
        case signup
    }

    var body: some View {
        Group {
            if currentView == .login {
                ZStack {
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
                        TextField(
                            "",
                            text: $email,
                            prompt: Text("Email").foregroundColor(theme.inputBoxForeground.opacity(0.6))
                        )
                        .font(.system(size: 20))
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 18)
                        .frame(height: 50)
                        .background(theme.inputBoxBackground)
                        .overlay(Capsule().stroke(theme.border, lineWidth: 2))
                        .clipShape(Capsule())
                        .padding(.horizontal)
                        .disabled(isLoading)

                        // Password
                        SecureField(
                            "",
                            text: $password,
                            prompt: Text("Password").foregroundColor(theme.inputBoxForeground.opacity(0.6))
                        )
                        .font(.system(size: 20))
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 18)
                        .frame(height: 50)
                        .background(theme.inputBoxBackground)
                        .overlay(Capsule().stroke(theme.border, lineWidth: 2))
                        .clipShape(Capsule())
                        .padding(.horizontal)
                        .disabled(isLoading)

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                                .accessibilityLabel("Error: \(errorMessage)")
                        }

                        VStack(spacing: 15) {
                            Button(action: { Task { await login() } }) {
                                Group {
                                    if isLoading {
                                        ProgressView()
                                    } else {
                                        Text("Login")
                                            .font(.headline)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(theme.primary)
                                .foregroundColor(theme.primaryText)
                                .overlay(Capsule().stroke(theme.border, lineWidth: 2))
                                .clipShape(Capsule())
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal)

                        Button(action: { currentView = .signup }) {
                            Text("Don't have an account? Sign Up")
                                .foregroundColor(theme.accentThird)
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
        SessionManager.shared.startSession(jwt: authResponse.jwt, user: authResponse.user)
        isLoggedIn = true
    }
}
