import SwiftUI
import KeychainAccess

struct SignupView: View {
    @Binding var isLoggedIn: Bool // Binding to control login state
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isSignupSuccessful = false // To control navigation to LoginView

    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Sign Up for GeniusParentingAISwift")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: {
                    signup()
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)

                Button(action: {
                    // Navigate back to LoginView
                    isSignupSuccessful = true
                }) {
                    Text("Already have an account? Log In")
                        .foregroundColor(.blue)
                }
                .padding()
            }
            .padding()

            // Show LoginView after successful signup or manual navigation
            if isSignupSuccessful {
                LoginView(isLoggedIn: $isLoggedIn)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
        }
    }

    func signup() {
        // Basic validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        // Strapi signup endpoint
        let url = URL(string: "https://strapi.geniusparentingai.ca/api/auth/local/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["username": email, "email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Network error: \(error.localizedDescription)") // Debug log
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response from server"
                    return
                }
                print("Status code: \(httpResponse.statusCode)") // Debug log
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("Response data: \(dataString)") // Debug log
                }
                guard httpResponse.statusCode == 200,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let jwt = json["jwt"] as? String else {
                    errorMessage = "Signup failed. Please try again."
                    return
                }
                // Store JWT and navigate to LoginView
                keychain["jwt"] = jwt
                isSignupSuccessful = true
            }
        }.resume()
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView(isLoggedIn: .constant(false))
    }
}
