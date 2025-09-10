import SwiftUI
import KeychainAccess
final class MainTabRouter: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var needsCourseViewReset: Bool = false
}

struct MainView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isLoggedIn: Bool
    let logoutAction: () -> Void
    
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var selectedTab: Int = 0
    @AppStorage("hasCompletedPersonalityTest") private var hasCompletedPersonalityTest = false
    @AppStorage("personalityReminderSuppressed") private var personalityReminderSuppressed = false
    @StateObject private var tabRouter = MainTabRouter()
    
    // Existing sheets
    @State private var selectedLanguage = "en"
    @State private var isShowingLanguageSheet = false
    @State private var isShowingProfileSheet = false
    @State private var isShowingSettingSheet = false
    @State private var isShowingThemeSheet = false
    @State private var isShowingPrivacySheet = false
    @State private var isShowingTermsSheet = false
    @State private var isShowingSubscriptionSheet = false
    @State private var isShowingBlockedUsers = false

    @State private var isSideMenuShowing = false
    @State private var showPersonalityPrompt = false
    @State private var showOnboarding = false
    @State private var didCheckReminderOnce = false

    var body: some View {
        ZStack {
            // Apply the gradient to the ZStack directly, making it the base layer
            LinearGradient(
                colors: [themeManager.currentTheme.background, themeManager.currentTheme.background2],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea() // Ensure the gradient fills the entire safe area

            // 2) Bind TabView to the router
            TabView(selection: $tabRouter.selectedTab) {
                homeTab
                    .tabItem {
                        Image("button-home").renderingMode(.template)
                        Text("Home")
                    }
                    .tag(0)

                courseTab
                    .tabItem {
                        Image("button-courses").renderingMode(.template)
                        Text("Course")
                    }
                    .tag(1)

                aiTab
                    .tabItem {
                        Image("button-ai").renderingMode(.template)
                        Text("AI")
                    }
                    .tag(2)

                communityTab
                    .tabItem {
                        Image("button-community").renderingMode(.template)
                        Text("Community")
                    }
                    .tag(3)
            }
            .background(Color.clear) // Keep background clear for TabView to show gradient below
            .environmentObject(tabRouter)   // ⬅️ this is the line you asked about
            .onAppear {
                // Configure UITabBarAppearance for a solid background to cover the gradient
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground() // Use opaque background
                appearance.backgroundColor = UIColor(themeManager.currentTheme.background) // Set to a solid background color
                appearance.shadowColor = .clear // Remove any shadow line if not desired
                
                // Set the text color for selected and unselected states using theme colors
                let selectedItemColor = UIColor(themeManager.currentTheme.primary) // Example: use theme's primary for selected
                let unselectedItemColor = UIColor(themeManager.currentTheme.foreground.opacity(0.6)) // Example: use theme's foreground for unselected

                appearance.stackedLayoutAppearance.selected.iconColor = selectedItemColor
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedItemColor]
                
                appearance.stackedLayoutAppearance.normal.iconColor = unselectedItemColor
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedItemColor]

                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
                //UITabBar.appearance().compactAppearance = appearance // For compact height scenarios
                
                maybeShowPersonalityPromptOnce()
            }
            .onChange(of: themeManager.currentTheme.id) { _ in
                // Re-apply appearance when theme changes
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(themeManager.currentTheme.background)
                appearance.shadowColor = .clear
                
                let selectedItemColor = UIColor(themeManager.currentTheme.primary)
                let unselectedItemColor = UIColor(themeManager.currentTheme.foreground.opacity(0.6))

                appearance.stackedLayoutAppearance.selected.iconColor = selectedItemColor
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedItemColor]
                
                appearance.stackedLayoutAppearance.normal.iconColor = unselectedItemColor
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedItemColor]

                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
                //UITabBar.appearance().compactAppearance = appearance
            }
            .fullScreenCover(isPresented: $isShowingSubscriptionSheet) {
                SubscriptionView(isPresented: $isShowingSubscriptionSheet)
            }
            
            if isSideMenuShowing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) { isSideMenuShowing = false }
                    }
                    .transition(.opacity)
                    .zIndex(1)
            }

            SideMenuView(
                isShowing: $isSideMenuShowing,
                profileViewModel: profileViewModel,
                isShowingProfileSheet: $isShowingProfileSheet,
                isShowingLanguageSheet: $isShowingLanguageSheet,
                isShowingSettingSheet: $isShowingSettingSheet,
                //isShowingThemeSheet: $isShowingThemeSheet,
                logoutAction: logoutAction,
                isShowingPrivacySheet: $isShowingPrivacySheet,
                isShowingTermsSheet: $isShowingTermsSheet,
                isShowingSubscriptionSheet: $isShowingSubscriptionSheet,
                isShowingBlockedUsers: $isShowingBlockedUsers
            )
            .frame(width: UIScreen.main.bounds.width * 0.7)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .offset(x: isSideMenuShowing ? 0 : UIScreen.main.bounds.width)
            .ignoresSafeArea()
            .zIndex(2)
            
            if isShowingProfileSheet {
                ProfileView(
                    isLoggedIn: $isLoggedIn,
                    viewModel: profileViewModel,
                    isPresented: $isShowingProfileSheet
                )
                .environmentObject(tabRouter)
                .transition(.move(edge: .leading))
                .zIndex(3)
            }
            
            if isShowingLanguageSheet {
                LanguagePickerView(selectedLanguage: $selectedLanguage, isPresented: $isShowingLanguageSheet)
                    .transition(.move(edge: .leading))
                    .zIndex(3)
            }
            
            if isShowingSettingSheet {
                SettingView(isPresented: $isShowingSettingSheet)
                    .transition(.move(edge: .leading))
                    .zIndex(3)
            }

            if isShowingThemeSheet {
                ThemeSelectView(isPresented: $isShowingThemeSheet)
                    .transition(.move(edge: .leading))
                    .zIndex(3)
            }

            if isShowingPrivacySheet {
                PrivacyPolicyView(isPresented: $isShowingPrivacySheet)
                    .transition(.move(edge: .leading))
                    .zIndex(3)
            }
            
            if isShowingTermsSheet {
                TermsOfServiceView(isPresented: $isShowingTermsSheet)
                    .transition(.move(edge: .leading))
                    .zIndex(3)
            }
            if isShowingBlockedUsers {
                NavigationStack {
                    BlockedUsersView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    withAnimation(.easeInOut) { isShowingBlockedUsers = false }
                                } label: {
                                    Label("Close", systemImage: "xmark")
                                }
                            }
                        }
                }
                .transition(.move(edge: .leading))
                .zIndex(3)
            }
        }
        .animation(.easeInOut, value: isSideMenuShowing)
        .animation(.easeInOut, value: isShowingProfileSheet)
        .animation(.easeInOut, value: isShowingLanguageSheet)
        .animation(.easeInOut, value: isShowingSettingSheet)
        .animation(.easeInOut, value: isShowingThemeSheet)
        .animation(.easeInOut, value: isShowingPrivacySheet)
        .animation(.easeInOut, value: isShowingTermsSheet)
        .animation(.easeInOut, value: isShowingSubscriptionSheet)
        .animation(.easeInOut, value: isShowingBlockedUsers)
        .alert("Try the 30-sec Personality Test?", isPresented: $showPersonalityPrompt) {
            Button("Not now") { personalityReminderSuppressed = true; showPersonalityPrompt = false }
            Button("Take the test") { showPersonalityPrompt = false; showOnboarding = true }
        } message: {
            Text("This helps tailor tips and lessons to you.")
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(didComplete: $hasCompletedPersonalityTest)
                .environmentObject(themeManager)
               .environmentObject(tabRouter)
        }
        .onChange(of: hasCompletedPersonalityTest) { done in
            if done { showOnboarding = false }
        }
        .appGradientBackground()
    }
    
    private var menuToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                withAnimation(.easeInOut) { isSideMenuShowing.toggle() }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.title3)
            }
        }
    }

    private func maybeShowPersonalityPromptOnce() {
        guard !didCheckReminderOnce else { return }
        didCheckReminderOnce = true

        let shouldPrompt = !hasCompletedPersonalityTest && !personalityReminderSuppressed

        if shouldPrompt {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showOnboarding = true
            }
        }
    }
    
    private var homeTab: some View {
        NavigationView {
            HomeView(selectedLanguage: $selectedLanguage, isSideMenuShowing: $isSideMenuShowing)
                // Set toolbar background to clear for transparency
                //.toolbarBackground(Color.clear, for: .navigationBar)
                //.toolbarBackground(.visible, for: .navigationBar)
                //.toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .tint(themeManager.currentTheme.accent)
    }

    private var courseTab: some View {
        NavigationStack {
            CourseView(selectedLanguage: $selectedLanguage, isSideMenuShowing: $isSideMenuShowing)
                .navigationTitle("Courses") // Keep this for accessibility
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Courses")
                            .font(.headline) // Optional: matches the default title font
                            .foregroundColor(themeManager.currentTheme.inputBoxForeground)
                    }
                    menuToolbar
                }
        }
        .tint(themeManager.currentTheme.accent)
    }

    private var aiTab: some View {
        NavigationView {
            AIView()
                .navigationTitle("AI Assistant")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("AI Assistant")
                            .font(.headline).foregroundColor(themeManager.currentTheme.inputBoxForeground)
                    }
                    menuToolbar
                }
                //.toolbarBackground(Color.clear, for: .navigationBar)
                //.toolbarBackground(.visible, for: .navigationBar)
                //.toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .tint(themeManager.currentTheme.accent)
    }

    private var communityTab: some View {
        NavigationView {
            CommunityView()
                .navigationTitle("Community")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement:.principal) {
                        Text("Community").font(.headline).foregroundColor(themeManager.currentTheme.inputBoxForeground)
                    }
                    menuToolbar
                }
                // Set toolbar background to clear for transparency
                //.toolbarBackground(Color.clear, for: .navigationBar)
                //.toolbarBackground(.visible, for: .navigationBar)
                //.toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .tint(themeManager.currentTheme.accent)
    }
}

// Language Picker View
struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                Button("English") { selectedLanguage = "en"; isPresented = false }
                Button("Spanish") { selectedLanguage = "es"; isPresented = false }
            }
            .navigationTitle("Select Language")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(isLoggedIn: .constant(true), logoutAction: {})
            .environmentObject(ThemeManager())
    }
}
