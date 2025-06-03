import SwiftUI
import KeychainAccess

struct LoginView: View {
    @Binding var isLoggedIn: Bool // Binding to control login state
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isShowingSignup = false // To control navigation to SignupView

    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("GeniusParentingAISwift")
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

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: {
                    login()
                }) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)

                Button(action: {
                    // Navigate to SignupView
                    isShowingSignup = true
                }) {
                    Text("Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                .padding()
            }
            .padding()

            // Show SignupView when requested
            if isShowingSignup {
                SignupView(isLoggedIn: $isLoggedIn)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
        }
    }

    func login() {
        let url = URL(string: "https://strapi.geniusparentingai.ca/api/auth/local")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["identifier": email, "password": password]
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
                    errorMessage = "Invalid email or password"
                    return
                }
                keychain["jwt"] = jwt
                isLoggedIn = true
            }
        }.resume()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
