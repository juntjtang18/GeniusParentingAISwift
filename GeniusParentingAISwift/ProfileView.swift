import SwiftUI
import KeychainAccess

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isShowingEditView = false
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
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
                if viewModel.user == nil {
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
            ProfileView(isLoggedIn: .constant(true), isPresented: .constant(true))
        }
    }
}
