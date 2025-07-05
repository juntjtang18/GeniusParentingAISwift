import SwiftUI
import KeychainAccess

struct SignupView: View {
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
                .padding()
                Spacer()
            }

            Text("Sign Up for Genius Parenting AI")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

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
                signup()
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
        .padding()
    }

    func signup() {
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

        let url = URL(string: "\(Config.strapiBaseUrl)/api/auth/local/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["username": email, "email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                // Handle network-level errors
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    errorMessage = "Network error: Please check your connection and try again."
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                    errorMessage = "Invalid response from server."
                    return
                }
                
                // Decode the response
                do {
                    // Successful registration (200 OK)
                    if httpResponse.statusCode == 200 {
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        if let jwt = json?["jwt"] as? String {
                            keychain["jwt"] = jwt
                            // Optionally, you could decode the user object here too
                            // For now, we just switch to the login view for simplicity
                            currentView = .login
                        } else {
                            errorMessage = "Registration succeeded but no token was received."
                        }
                    } else {
                        // Handle Strapi error responses (e.g., 400 Bad Request)
                        let errorResponse = try JSONDecoder().decode(StrapiErrorResponse.self, from: data)
                        errorMessage = errorResponse.error.message
                        print("Signup failed with status \(httpResponse.statusCode): \(errorResponse.error.message)")
                    }
                } catch {
                    // Fallback for unexpected JSON structure
                    errorMessage = "An unexpected error occurred. Please try again."
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("Failed to decode response: \(dataString)")
                    }
                }
            }
        }.resume()
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView(isLoggedIn: .constant(false), currentView: .constant(.signup))
    }
}
