// ProfileView.swift
import SwiftUI
import KeychainAccess

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isShowingEditView = false // State to control the edit sheet

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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Edit") {
                            isShowingEditView = true
                        }
                        // Disable the edit button if there is no profile to edit.
                        .disabled(viewModel.user?.user_profile == nil)
                    }
                }
                // MARK: MODIFICATION START
                .sheet(isPresented: $isShowingEditView) {
                    // Present the ProfileEditView when isShowingEditView is true.
                    ProfileEditView(isPresented: $isShowingEditView, viewModel: viewModel)
                }
                // MARK: MODIFICATION END
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
