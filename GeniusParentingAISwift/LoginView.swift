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
    
    let keychain = Keychain(service: Config.keychainService)

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
                        
                        Button(action: {
                            Task {
                                await login()
                            }
                        }) {
                            Text("Login")
                                //.frame(maxWidth: .infinity)
                                //.padding()
                                //.background(isLoading ? .gray : .themePrimary)
                                //.foregroundColor(.themeText)
                                //.clipShape(Capsule())
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                        .disabled(isLoading)
                        
                        
                        Button(action: {
                            currentView = .signup
                        }) {
                            Text("Don't have an account? Sign Up")
                                //.foregroundColor(.themeSecondary)
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
        
        let credentials = LoginCredentials(identifier: email, password: password)
        
        do {
            let authResponse = try await NetworkManager.shared.login(credentials: credentials)
            keychain["jwt"] = authResponse.jwt
            SessionManager.shared.currentUser = authResponse.user
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
