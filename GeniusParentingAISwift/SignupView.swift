// GeniusParentingAISwift/SignupView.swift

import SwiftUI
import KeychainAccess

struct SignupView: View {
    @Environment(\.theme) var theme: Theme
    @Binding var isLoggedIn: Bool
    @Binding var currentView: LoginView.ViewState
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false // To show a loading indicator

    let keychain = Keychain(service: Config.keychainService)

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    currentView = .login
                }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .buttonStyle(LinkStyleButtonStyle()) // Use link style for back button
                .padding()
                Spacer()
            }

            Text("Sign Up for Genius Parenting AI")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(theme.foreground)

            TextField("Email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)
                .disabled(isLoading)

            SecureField("Password", text: $password)
                .padding(.horizontal)
                .disabled(isLoading)

            SecureField("Confirm Password", text: $confirmPassword)
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

            Button(action: {
                Task {
                   await signup()
                }
            }) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle()) // Use the main button style
            .padding(.horizontal)
            .disabled(isLoading)

            Button(action: {
                currentView = .login
            }) {
                Text("Already have an account? Log In")
            }
            .buttonStyle(LinkStyleButtonStyle()) // Use link style
            .padding()
        }
        .textFieldStyle(ThemedTextFieldStyle())
        .padding()
        .background(theme.background.ignoresSafeArea()) // Ensure background is set
    }

    func signup() async {
        guard !isLoading else { return }
        
        errorMessage = ""
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isLoading = true
        
        let payload = RegistrationPayload(username: email, email: email, password: password)

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
