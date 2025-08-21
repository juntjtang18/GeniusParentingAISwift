import SwiftUI
import KeychainAccess

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @ObservedObject var viewModel: ProfileViewModel
    @State private var isShowingEditView = false
    @Binding var isPresented: Bool

    private let manageSubscriptionURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    var body: some View {
        NavigationView {
            VStack {
                if !isLoggedIn {
                    Text("Please log in to view your profile.")
                        .foregroundColor(.secondary)
                        .padding()
                } else if viewModel.isLoading {
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
                } else if viewModel.user == nil {
                    Text("No profile data available.")
                        .foregroundColor(.secondary)
                        .padding()
                } else if let user = viewModel.user {
                    List {
                        Section(header: Text("Account Details")) {
                            ProfileRow(label: "Username", value: user.username)
                            ProfileRow(label: "Email", value: user.email)
                        }

                        Section(header: Text("Subscription")) {
                            Link("Manage Subscription", destination: manageSubscriptionURL)
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
                                Toggle(isOn: .constant(profile.consentForEmailNotice ?? false)) {
                                    Text("Email Notifications")
                                }
                                .disabled(true)
                            }
                            Section(header: Text("Personality Profile")) {
                                if let relation = profile.personality_result,
                                   let result = relation.data {

                                    let attrs = result.attributes
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(attrs.title)
                                            .font(.headline)
                                        Text(attrs.description)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                        if !attrs.powerTip.isEmpty {
                                            Divider().padding(.vertical, 4)
                                            HStack(alignment: .top, spacing: 8) {
                                                Image(systemName: "lightbulb")
                                                Text(attrs.powerTip)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            .accessibilityElement(children: .combine)
                                            .accessibilityLabel("Power tip")
                                            .accessibilityValue(attrs.powerTip)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                } else {
                                    Text("No personality result saved yet.")
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Section {
                                Text("No profile details found. Please complete your profile.")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(GroupedListStyle())
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        isShowingEditView = true
                    }
                    .disabled(viewModel.user?.user_profile == nil)
                }
            }
            .sheet(isPresented: $isShowingEditView) {
                ProfileEditView(isPresented: $isShowingEditView, viewModel: viewModel)
            }
            .onAppear {
                if isLoggedIn {
                    Task {
                        await viewModel.fetchUserProfile()
                    }
                }
            }
        }
    }
}

struct ProfileRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView(
                isLoggedIn: .constant(true),
                viewModel: ProfileViewModel(),
                isPresented: .constant(true)
            )
        }
    }
}
