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

    // NEW: explicit consent
    @State private var agreedToPolicies = false

    // Policy URLs
    private let tosURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    private let privacyURL = "https://www.geniusparentingai.ca/privacy-policy"
    private let guidelinesURL = "https://www.geniusparentingai.ca/community-guidelines"

    let keychain = Keychain(service: Config.keychainService)

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.background, theme.background2],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("applogo-\(theme.id)")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .padding(.vertical, 20)

                // Username
                TextField("User Name", text: $username)
                    .font(.system(size: 20))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 18)
                    .frame(height: 50)
                    .background(theme.inputBoxBackground)
                    .foregroundColor(theme.inputBoxForeground)
                    .overlay(Capsule().stroke(theme.border, lineWidth: 1))
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .disabled(isLoading)

                // Email
                TextField("Email", text: $email)
                    .font(.system(size: 20))
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 18)
                    .frame(height: 50)
                    .background(theme.inputBoxBackground)
                    .foregroundColor(theme.inputBoxForeground)
                    .overlay(Capsule().stroke(theme.border, lineWidth: 1))
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .disabled(isLoading)

                // Password
                SecureField("Password", text: $password)
                    .font(.system(size: 20))
                    .padding(.horizontal, 18)
                    .frame(height: 50)
                    .background(theme.inputBoxBackground)
                    .foregroundColor(theme.inputBoxForeground)
                    .overlay(Capsule().stroke(theme.border, lineWidth: 1))
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .disabled(isLoading)

                // Errors / progress
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("Error: \(errorMessage)")
                }

                // CONSENT: third-person + links + toggle
                HStack {
                    if let md = try? AttributedString(
                        markdown:
                """
                By signing up, the user agrees to the [Terms of Service](\(tosURL)), [Privacy Policy](\(privacyURL)), and [Community Guidelines](\(guidelinesURL)).
                """
                    ) {
                        Text(md)
                            .font(.footnote)
                            .foregroundColor(theme.foreground)
                            .multilineTextAlignment(.leading)
                            .tint(theme.primary)
                    }

                    // ⬇️ Checkbox (replaces Toggle)
                    Button {
                        agreedToPolicies.toggle()
                    } label: {
                        Image(systemName: agreedToPolicies ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18, weight: .semibold))
                            //.foregroundColor(agreedToPolicies ? theme.primary : theme.border)
                            .padding(6)
                            //.background(theme.inputBoxBackground)   // match text fields
                            //.clipShape(Capsule())
                            //.overlay(
                            //    Capsule().stroke(theme.border, lineWidth: 1)
                            //)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Agree to Terms of Service, Privacy Policy, and Community Guidelines")
                    .accessibilityAddTraits(.isButton)
                }



                // Sign Up
                // Sign Up
                Button(action: { Task { await signup() } }) {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .tint(theme.primaryText)
                        } else {
                            Text("Sign Up")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                    .background(agreedToPolicies && !isLoading ? theme.primary : theme.primary.opacity(0.4))
                    .foregroundColor(theme.primaryText)
                    .overlay(Capsule().stroke(theme.border, lineWidth: 1))
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
                .disabled(isLoading || !agreedToPolicies)


                // Switch to Login
                Button(action: { currentView = .login }) {
                    Text("Already have an account? Login")
                }
                .foregroundColor(theme.accentThird)
            }
            .padding()
        }
    }

    func signup() async {
        guard !isLoading else { return }
        errorMessage = ""

        // minimal client-side validation
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        guard agreedToPolicies else {
            errorMessage = "Agreement to the Terms of Service, Privacy Policy, and Community Guidelines is required."
            return
        }

        isLoading = true
        let payload = RegistrationPayload(username: username, email: email, password: password) // uses shared models

        do {
            let authResponse = try await NetworkManager.shared.signup(payload: payload)
            keychain["jwt"] = authResponse.jwt
            // optional: isLoggedIn = true
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
