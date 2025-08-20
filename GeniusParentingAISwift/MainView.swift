// GeniusParentingAISwift/MainView.swift
import SwiftUI
import KeychainAccess

struct MainView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isLoggedIn: Bool
    let logoutAction: () -> Void
    
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var selectedTab: Int = 0
    
    // State management for sheets
    @State private var selectedLanguage = "en"
    @State private var isShowingLanguageSheet = false
    @State private var isShowingProfileSheet = false
    @State private var isShowingSettingSheet = false
    @State private var isShowingThemeSheet = false
    @State private var isShowingPrivacySheet = false
    @State private var isShowingTermsSheet = false
    @State private var isShowingSubscriptionSheet = false

    // State for the side menu
    @State private var isSideMenuShowing = false

    var body: some View {
        ZStack {
            // ADDED: Set the theme background as the bottom layer of the view
            themeManager.currentTheme.background
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
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
            .onAppear {
                updateUnselectedTabItemColor()
            }
            .onChange(of: themeManager.currentTheme.id) { _ in
                updateUnselectedTabItemColor()
            }
            .fullScreenCover(isPresented: $isShowingSubscriptionSheet) {
                SubscriptionView(isPresented: $isShowingSubscriptionSheet)
            }
            
            if isSideMenuShowing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isSideMenuShowing = false
                        }
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
    }
    
    private func updateUnselectedTabItemColor() {
        let theme = themeManager.currentTheme
        let colorName = "ColorSchemes/\(theme.id)/\(theme.id)Foreground"
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: colorName)
    }
    
    private var menuToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                withAnimation(.easeInOut) {
                    isSideMenuShowing.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.title3)
            }
        }
    }
    
    private var homeTab: some View {
        NavigationView {
            HomeView(selectedLanguage: $selectedLanguage, isSideMenuShowing: $isSideMenuShowing)
        }
        .navigationViewStyle(.stack)
    }
    
    private var courseTab: some View {
        NavigationStack {
            CourseView(selectedLanguage: $selectedLanguage, isSideMenuShowing: $isSideMenuShowing)
                .navigationTitle("Courses")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { menuToolbar }
        }
    }
    
    private var aiTab: some View {
        NavigationView {
            AIView()
                .navigationTitle("AI Assistant")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            selectedTab = 0
                        }) {
                            Image(systemName: "chevron.left")
                            Text("Home")
                        }
                    }
                    menuToolbar
                }
        }
        .navigationViewStyle(.stack)
    }
    
    private var communityTab: some View {
        NavigationView {
            CommunityView()
                .navigationTitle("Community")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { menuToolbar }
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
