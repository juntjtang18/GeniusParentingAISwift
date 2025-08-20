// GeniusParentingAISwift/SignupView.swift

import SwiftUI
import KeychainAccess

struct SignupView: View {
    @Environment(\.theme) var theme: Theme
    @Binding var isLoggedIn: Bool
    @Binding var currentView: LoginView.ViewState
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    let keychain = Keychain(service: Config.keychainService)

    var body: some View {
        // CHANGED: Root view is now a ZStack to match LoginView's structure for vertical centering.
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Image("login-image")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .padding(.vertical, 20)

                TextField("User Name", text: $username)
                    .font(.system(size: 20))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 18)
                    .frame(height: 50)
                    .background(theme.inputBoxBackground)
                    .foregroundColor(theme.foreground)
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .disabled(isLoading)

                TextField("Email", text: $email)
                    .font(.system(size: 20))
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 18)
                    .frame(height: 50)
                    .background(theme.inputBoxBackground)
                    .foregroundColor(theme.foreground)
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .disabled(isLoading)

                SecureField("Password", text: $password)
                    .font(.system(size: 20))
                    .padding(.horizontal, 18)
                    .frame(height: 50)
                    .background(theme.inputBoxBackground)
                    .foregroundColor(theme.foreground)
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .disabled(isLoading)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                if isLoading {
                    ProgressView()
                        .padding()
                }
                
                Button(action: { Task { await signup() } }) {
                    Text("Sign Up")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(theme.primary)
                        .foregroundColor(theme.primaryText)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)
                .disabled(isLoading)


                Button(action: {
                    currentView = .login
                }) {
                    Text("Already have an account? Login")
                }
                .buttonStyle(LinkStyleButtonStyle())
                .padding(.top)

                Button(action: {
                    // TODO: Implement Google Sign-In action
                }) {
                    HStack {
                        Image("google-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Continue with Google")
                            .font(.headline)
                            .foregroundColor(theme.accent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(theme.accentBackground)
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // REMOVED: The Spacer that was pushing content to the top is gone.
            }
            .padding()
        }
    }

    func signup() async {
        guard !isLoading else { return }
        
        errorMessage = ""
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        
        let payload = RegistrationPayload(username: username, email: email, password: password)

        do {
            let authResponse = try await NetworkManager.shared.signup(payload: payload)
            keychain["jwt"] = authResponse.jwt
            currentView = .login
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView(isLoggedIn: .constant(false), currentView: .constant(.signup))
            .environmentObject(ThemeManager())
    }
}
