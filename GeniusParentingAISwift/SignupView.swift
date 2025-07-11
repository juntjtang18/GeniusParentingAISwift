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
                        .foregroundColor(theme.text)
                }
                .padding()
                Spacer()
            }

            Text("Sign Up for Genius Parenting AI")
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

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
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
                    .padding()
                    .background(isLoading ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .disabled(isLoading)

            Button(action: {
                currentView = .login
            }) {
                Text("Already have an account? Log In")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .textFieldStyle(ThemedTextFieldStyle())
        .padding()
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
            // Redirect to login view for the user to log in after successful signup
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
    }
}
