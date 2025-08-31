// GeniusParentingAISwift/ProfileView.swift
import SwiftUI
import KeychainAccess

// ✅ MAIN VIEW: Now a simple container for state and navigation.
struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var isPresented: Bool

    @State private var isShowingEditView = false
    @State private var isShowingOnboarding = false
    @State private var onboardingDidComplete = false
    @EnvironmentObject var tabRouter: MainTabRouter

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
                    ErrorView(errorMessage: errorMessage) {
                        await viewModel.fetchUserProfile()
                    }
                } else if let user = viewModel.user {
                    // All profile details are now in this self-contained view
                    ProfileDetailsList(
                        user: user,
                        isShowingOnboarding: $isShowingOnboarding
                    )
                } else {
                    Text("No profile data available.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") { isShowingEditView = true }
                        .disabled(viewModel.user?.user_profile == nil)
                }
            }
            .sheet(isPresented: $isShowingEditView) {
                ProfileEditView(isPresented: $isShowingEditView, viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $isShowingOnboarding) {
                OnboardingFlowView(didComplete: $onboardingDidComplete)
                    .environmentObject(tabRouter)
            }
            .onChange(of: onboardingDidComplete) { completed in
                if completed {
                    isShowingOnboarding = false
                    onboardingDidComplete = false
                    Task { await viewModel.fetchUserProfile() }
                    isPresented = false
                }
            }
            .onAppear {
                if isLoggedIn {
                    Task { await viewModel.fetchUserProfile() }
                }
            }
        }
    }
}

// MARK: - Subviews for Profile Content

// ✅ NEW: This view contains the main List of profile details.
private struct ProfileDetailsList: View {
    let user: StrapiUser
    @Binding var isShowingOnboarding: Bool
    
    private let manageSubscriptionURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    var body: some View {
        List {
            Section(header: Text("Account Details")) {
                ProfileRow(label: "Username", value: user.username)
                ProfileRow(label: "Email", value: user.email)
            }

            Section(header: Text("Subscription")) {
                Link("Manage Subscription", destination: manageSubscriptionURL)
            }
            
            if let profile = user.user_profile {
                FamilyInformationSection(children: profile.children ?? [])
                
                PreferencesSection(consent: profile.consentForEmailNotice ?? false)
                
                PersonalityProfileSection(
                    result: profile.personality_result,
                    isShowingOnboarding: $isShowingOnboarding
                )
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

// ✅ NEW: A dedicated view for the Family Information section.
private struct FamilyInformationSection: View {
    let children: [Child]

    var body: some View {
        Section(header: Text("Family Information")) {
            if !children.isEmpty {
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
    }
}

// ✅ NEW: A dedicated view for the Preferences section.
private struct PreferencesSection: View {
    let consent: Bool

    var body: some View {
        Section(header: Text("Preferences")) {
            Toggle(isOn: .constant(consent)) {
                Text("Email Notifications")
            }
            .disabled(true)
        }
    }
}

// ✅ NEW: A dedicated view for the Personality Profile section.
private struct PersonalityProfileSection: View {
    let result: InlinePersonalityResult?
    @Binding var isShowingOnboarding: Bool

    var body: some View {
        Section(header: Text("Personality Profile")) {
            if let result = result {
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.title)
                        .font(.headline)
                    Text(result.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if !result.powerTip.isEmpty {
                        Divider().padding(.vertical, 4)
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb")
                            Text(result.powerTip)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                Button("Retake Personality Test") {
                    isShowingOnboarding = true
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Text("No personality result saved yet.")
                    .foregroundColor(.secondary)
                
                Button("Start Personality Test") {
                    isShowingOnboarding = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

// MARK: - Helper Views

private struct ErrorView: View {
    let errorMessage: String
    let onRetry: () async -> Void

    var body: some View {
        VStack {
            Text(errorMessage)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
            Button("Retry") {
                Task { await onRetry() }
            }
            .padding()
        }
    }
}

private struct ProfileRow: View {
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

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView(
                isLoggedIn: .constant(true),
                viewModel: ProfileViewModel(),
                isPresented: .constant(true)
            )
            .environmentObject(MainTabRouter())
        }
    }
}
