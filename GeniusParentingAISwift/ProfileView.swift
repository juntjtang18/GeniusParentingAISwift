// ProfileView.swift
import SwiftUI
import KeychainAccess

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var viewModel = ProfileViewModel()

    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Profile...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        Task {
                            await viewModel.fetchUserProfile()
                        }
                    }
                    .padding()
                }
            } else if let user = viewModel.user {
                List {
                    Section(header: Text("Account Details")) {
                        ProfileRow(label: "Username", value: user.username)
                        ProfileRow(label: "Email", value: user.email)
                    }

                    if let profile = user.user_profile {
                        Section(header: Text("Family Information")) {
                            ProfileRow(label: "Number of Children", value: "\(profile.numberOfChildren ?? 0)")

                            if let children = profile.children, !children.isEmpty {
                                ForEach(children) { child in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(child.name).font(.headline)
                                        Text("Age: \(child.age) | Gender: \(child.gender)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 5)
                                }
                            } else {
                                Text("No child details added.")
                                    .foregroundColor(.secondary)
                            }
                        }

                        Section(header: Text("Preferences")) {
                            Toggle(isOn: .constant(profile.consentForEmailNotice)) {
                                Text("Email Notifications")
                            }
                            .disabled(true)
                        }
                    } else {
                        Section {
                            Text("No profile details found. Please complete your profile.")
                                .foregroundColor(.secondary)
                        }
                    }

                    Section {
                         Button(action: {
                             keychain["jwt"] = nil
                             keychain["user_id"] = nil // Also clear the user_id on logout
                             isLoggedIn = false
                         }) {
                             Text("Logout")
                                 .foregroundColor(.red)
                                 .frame(maxWidth: .infinity, alignment: .center)
                         }
                    }
                }
                .listStyle(GroupedListStyle())
            }
        }
        .onAppear {
            print("ProfileView: .onAppear triggered.")
            if viewModel.user == nil {
                Task {
                    await viewModel.fetchUserProfile()
                }
            }
        }
    }
}

/// A helper view for consistent row layout in the profile.
struct ProfileRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label).fontWeight(.semibold)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(isLoggedIn: .constant(true))
    }
}
