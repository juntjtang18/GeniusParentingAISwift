import SwiftUI
import KeychainAccess

struct SignupView: View {
    @Binding var isLoggedIn: Bool // Binding to control login state
    @Binding var currentView: LoginView.ViewState // Binding to manage view state
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    var body: some View {
        VStack(spacing: 20) {
            // Custom Back Button
            HStack {
                Button(action: {
                    currentView = .login // Return to LoginView
                }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .padding()
                Spacer()
            }

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
                currentView = .login // Navigate back to LoginView
            }) {
                Text("Already have an account? Log In")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .padding()
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
        let url = URL(string: "\(Config.strapiBaseUrl)/api/auth/local/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["username": email, "email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response from server"
                    return
                }
                print("Status code: \(httpResponse.statusCode)")
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("Response data: \(dataString)")
                }
                guard httpResponse.statusCode == 200,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let jwt = json["jwt"] as? String else {
                    errorMessage = "Signup failed. Please try again."
                    return
                }
                keychain["jwt"] = jwt
                currentView = .login // Navigate back to LoginView after successful signup
            }
        }.resume()
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView(isLoggedIn: .constant(false), currentView: .constant(.signup))
    }
}
