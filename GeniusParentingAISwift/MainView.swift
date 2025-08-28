import SwiftUI
import KeychainAccess
final class MainTabRouter: ObservableObject {
    @Published var selectedTab: Int = 0
}
struct MainView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isLoggedIn: Bool
    let logoutAction: () -> Void
    
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var selectedTab: Int = 0
    @AppStorage("hasCompletedPersonalityTest") private var hasCompletedPersonalityTest = false
    @AppStorage("personalityReminderSuppressed") private var personalityReminderSuppressed = false
    @StateObject private var tabRouter = MainTabRouter()      // ⬅️ add

    // Existing sheets
    @State private var selectedLanguage = "en"
    @State private var isShowingLanguageSheet = false
    @State private var isShowingProfileSheet = false
    @State private var isShowingSettingSheet = false
    @State private var isShowingThemeSheet = false
    @State private var isShowingPrivacySheet = false
    @State private var isShowingTermsSheet = false
    @State private var isShowingSubscriptionSheet = false

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
                updateTabBarAppearance()
                maybeShowPersonalityPromptOnce()
            }
            .onChange(of: themeManager.currentTheme.id) { _ in
                updateTabBarAppearance()
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
                isShowingThemeSheet: $isShowingThemeSheet,
                logoutAction: logoutAction,
                isShowingPrivacySheet: $isShowingPrivacySheet,
                isShowingTermsSheet: $isShowingTermsSheet,
                isShowingSubscriptionSheet: $isShowingSubscriptionSheet
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
        }
        .tint(themeManager.currentTheme.primary)
        .animation(.easeInOut, value: isSideMenuShowing)
        .animation(.easeInOut, value: isShowingProfileSheet)
        .animation(.easeInOut, value: isShowingLanguageSheet)
        .animation(.easeInOut, value: isShowingSettingSheet)
        .animation(.easeInOut, value: isShowingThemeSheet)
        .animation(.easeInOut, value: isShowingPrivacySheet)
        .animation(.easeInOut, value: isShowingTermsSheet)
        .animation(.easeInOut, value: isShowingSubscriptionSheet)
        .alert("Try the 30-sec Personality Test?", isPresented: $showPersonalityPrompt) {
            Button("Not now") { personalityReminderSuppressed = true; showPersonalityPrompt = false }
            Button("Take the test") { showPersonalityPrompt = false; showOnboarding = true }
        } message: {
            Text("This helps tailor tips and lessons to you.")
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(didComplete: $hasCompletedPersonalityTest)
                .environmentObject(themeManager)
        }
        .onChange(of: hasCompletedPersonalityTest) { done in
            if done { showOnboarding = false }
        }
        .appGradientBackground()
    }
    
    private func updateTabBarAppearance() {
        let theme = themeManager.currentTheme
        let colorName = "ColorSchemes/\(theme.id)/\(theme.id)Foreground"
        let backgroundColorName = "ColorSchemes/\(theme.id)/\(theme.id)Background"
        
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: colorName)
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        // Here we'll need to handle the gradient for the tab bar background if desired,
        // but for now, let's keep it simple to ensure the main view works.
        // For a gradient tab bar, you'd typically render it as a custom view.
        appearance.backgroundColor = UIColor(named: backgroundColorName)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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

    // NEW: Only check once when MainView first appears after login
    private func maybeShowPersonalityPromptOnce() {
        guard !didCheckReminderOnce else { return }
        didCheckReminderOnce = true

        let shouldPrompt = !hasCompletedPersonalityTest && !personalityReminderSuppressed

        if shouldPrompt {
            // Slight delay so we don’t clash with first layout/animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showPersonalityPrompt = true
            }
        }
    }
    
    private var homeTab: some View {
        NavigationView {
            HomeView(selectedLanguage: $selectedLanguage, isSideMenuShowing: $isSideMenuShowing)
                // The HomeView itself will now handle its gradient background.
                // We ensure navigation bar also has gradient background.
                .toolbarBackground(
                                LinearGradient(colors: [themeManager.currentTheme.background, themeManager.currentTheme.background2],
                                               startPoint: .top, endPoint: .bottom),
                                for: .navigationBar
                            )
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
    }

    private var courseTab: some View {
        NavigationStack {
            CourseView(selectedLanguage: $selectedLanguage, isSideMenuShowing: $isSideMenuShowing)
                .background(Color.clear) // Ensure CourseView's background is clear to show the gradient from MainView
                .navigationTitle("Courses")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { menuToolbar }
                // Apply gradient to the navigation bar for CourseView as well
                .toolbarBackground(
                                LinearGradient(colors: [themeManager.currentTheme.background, themeManager.currentTheme.background2],
                                               startPoint: .top, endPoint: .bottom),
                                for: .navigationBar
                            )
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var aiTab: some View {
        NavigationView {
            AIView()
                .navigationTitle("AI Assistant")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { selectedTab = 0 }) {
                            Image(systemName: "chevron.left")
                            Text("Home")
                        }
                    }
                    menuToolbar
                }
                // Apply gradient to the navigation bar for AIView
                .toolbarBackground(
                                LinearGradient(colors: [themeManager.currentTheme.background, themeManager.currentTheme.background2],
                                               startPoint: .top, endPoint: .bottom),
                                for: .navigationBar
                            )
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
    }

    private var communityTab: some View {
        NavigationView {
            CommunityView()
                .navigationTitle("Community")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { menuToolbar }
                // Apply gradient to the navigation bar for CommunityView
                .toolbarBackground(
                                LinearGradient(colors: [themeManager.currentTheme.background, themeManager.currentTheme.background2],
                                               startPoint: .top, endPoint: .bottom),
                                for: .navigationBar
                            )
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
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
