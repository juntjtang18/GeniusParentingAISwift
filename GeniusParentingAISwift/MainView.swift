// GeniusParentingAISwift/MainView.swift
import SwiftUI
import KeychainAccess

struct MainView: View {
    @EnvironmentObject var themeManager: ThemeManager // 1. Get the theme manager
    @Binding var isLoggedIn: Bool
    @State private var selectedTab: Int = 0
    
    // State management for sheets
    @State private var selectedLanguage = "en"
    @State private var isShowingLanguageSheet = false
    @State private var isShowingProfileSheet = false
    @State private var isShowingSettingSheet = false
    @State private var isShowingThemeSheet = false
    @State private var isShowingPrivacySheet = false
    @State private var isShowingTermsSheet = false
    @State private var isShowingSubscriptionSheet = false // ADDED: State for the new view

    // State for the side menu
    @State private var isSideMenuShowing = false

    @StateObject private var homeViewModel = HomeViewModel()

    let keychain = Keychain(service: Config.keychainService)

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                homeTab
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)

                courseTab
                    .tabItem {
                        Image(systemName: "book.fill")
                        Text("Course")
                    }
                    .tag(1)

                aiTab
                    .tabItem {
                        Image(systemName: "brain.fill")
                        Text("AI")
                    }
                    .tag(2)

                communityTab
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Community")
                    }
                    .tag(3)
            }
            .accentColor(themeManager.currentTheme.accent)
            .onAppear {
                updateUnselectedTabItemColor()
            }
            .onChange(of: themeManager.currentTheme.id) { _ in
                updateUnselectedTabItemColor()
            }
            
            // --- Side Menu Layer ---
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

            // --- REVISED: Position Side Menu without HStack/Spacer ---
            SideMenuView(
                isShowing: $isSideMenuShowing,
                isShowingProfileSheet: $isShowingProfileSheet,
                isShowingLanguageSheet: $isShowingLanguageSheet,
                isShowingSettingSheet: $isShowingSettingSheet,
                isShowingThemeSheet: $isShowingThemeSheet,
                isLoggedIn: $isLoggedIn,
                isShowingPrivacySheet: $isShowingPrivacySheet,
                isShowingTermsSheet: $isShowingTermsSheet,
                isShowingSubscriptionSheet: $isShowingSubscriptionSheet // ADDED: Pass the binding

            )
            .frame(width: UIScreen.main.bounds.width * 0.7)
            .frame(maxWidth: .infinity, alignment: .trailing) // Align to the right
            .offset(x: isSideMenuShowing ? 0 : UIScreen.main.bounds.width)
            .ignoresSafeArea()
            .zIndex(2)
            
            // --- Custom "Fly from Left" Views ---
            if isShowingProfileSheet {
                ProfileView(isLoggedIn: $isLoggedIn, isPresented: $isShowingProfileSheet)
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
            if isShowingSubscriptionSheet {
                SubscriptionView(isPresented: $isShowingSubscriptionSheet)
                    .transition(.move(edge: .leading))
                    .zIndex(3)
            }
        }
        .animation(.easeInOut, value: isSideMenuShowing) // Animate the side menu itself
        .animation(.easeInOut, value: isShowingProfileSheet)
        .animation(.easeInOut, value: isShowingLanguageSheet)
        .animation(.easeInOut, value: isShowingSettingSheet)
        .animation(.easeInOut, value: isShowingThemeSheet)
        .animation(.easeInOut, value: isShowingPrivacySheet)
        .animation(.easeInOut, value: isShowingTermsSheet)
        .animation(.easeInOut, value: isShowingSubscriptionSheet) // ADDED: Animation for new view

    }
    
    private func updateUnselectedTabItemColor() {
        let theme = themeManager.currentTheme
        // Construct the dynamic name for the color asset from your theme.
        let colorName = "ColorSchemes/\(theme.id)/\(theme.id)Text"
        // Use UIKit's appearance proxy to set the color for unselected items.
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: colorName)
    }
    // MARK: - Toolbar Content
    
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
    
    // MARK: - Tab Views
    
    private var homeTab: some View {
        NavigationView {
            HomeContentView(viewModel: homeViewModel, selectedLanguage: $selectedLanguage, isSideMenuShowing: $isSideMenuShowing)
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { menuToolbar }
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

struct HomeContentView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var selectedLanguage: String
    @Binding var isSideMenuShowing: Bool
    
    @State private var selectedTip: Tip? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                todaysLessonSection
                hotTopicsSection
                dailyTipsSection
                Spacer()
            }
            .padding(.vertical)
        }
        .background(
            Image("background1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
        .overlay {
            if let tip = selectedTip {
                FairyTipPopupView(tip: tip, isPresented: Binding(
                    get: { selectedTip != nil },
                    set: { if !$0 { withAnimation(.spring()) { selectedTip = nil } } }
                ))
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchDailyLessons()
                await viewModel.fetchHotTopics()
                await viewModel.fetchDailyTips()
            }
        }
    }
    
    private var todaysLessonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Lesson")
                .style(.homeSectionTitle)

            Group {
                if viewModel.isLoading {
                    ProgressView().frame(height: 250)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundColor(.red).padding().frame(height: 250)
                } else if viewModel.todaysLessons.isEmpty {
                     Text("No lessons scheduled for today.").foregroundColor(.gray).padding().frame(height: 250)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.todaysLessons) { lesson in
                                NavigationLink(destination: ShowACourseView(selectedLanguage: $selectedLanguage, courseId: lesson.id, isSideMenuShowing: $isSideMenuShowing)) {
                                    LessonCardView(lesson: lesson)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 250)
                }
            }
        }
    }
    
    private var hotTopicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hot Topics")
                .style(.homeSectionTitle)
            
            Group {
                if viewModel.isLoadingHotTopics {
                    ProgressView().frame(height: 250)
                } else if let errorMessage = viewModel.hotTopicsErrorMessage {
                    Text(errorMessage).foregroundColor(.red).padding().frame(height: 250)
                } else if viewModel.hotTopics.isEmpty {
                    Text("No hot topics available right now.").foregroundColor(.gray).padding().frame(height: 250)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.hotTopics) { topic in
                                NavigationLink(destination: TopicView(selectedLanguage: $selectedLanguage, topicId: topic.id, isSideMenuShowing: $isSideMenuShowing)) {
                                    HotTopicCardView(topic: topic)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 250)
                }
            }
        }
    }
    
    private var dailyTipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Tips")
                .style(.homeSectionTitle)

            Group {
                if viewModel.isLoadingDailyTips {
                    ProgressView().frame(height: 250)
                } else if let errorMessage = viewModel.dailyTipsErrorMessage {
                    Text(errorMessage).foregroundColor(.red).padding().frame(height: 250)
                } else if viewModel.dailyTips.isEmpty {
                    Text("No daily tips available right now.").foregroundColor(.gray).padding().frame(height: 250)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.dailyTips) { tip in
                                DailyTipCardView(tip: tip)
                                    .contentShape(Rectangle())
                                    .simultaneousGesture(
                                        TapGesture()
                                            .onEnded {
                                                print("Tapped DailyTipCardView: \(tip.text)")
                                                withAnimation(.spring()) {
                                                    self.selectedTip = tip
                                                }
                                            }
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 250)
                }
            }
        }
    }
}

// MARK: - New View for the Fairy Popup
struct FairyTipPopupView: View {
    let tip: Tip
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .background(.thinMaterial)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            ZStack(alignment: .top) {
                Image("fairy01")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220)
                    .offset(x: -180, y: -77)

                VStack(spacing: 0) {
                    ZStack {
                        AsyncImage(url: URL(string: tip.iconImageMedia?.attributes.url ?? "")) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable()
                                     .scaledToFill()
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    .frame(height: 200)
                    .clipped()

                    ScrollView {
                        Text(tip.text)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    
                    Spacer()

                    Button("Got it!") { isPresented = false }
                        .font(.headline)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                        .foregroundColor(.black.opacity(0.7))
                }
                .frame(width: 300, height: 420)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(red: 0.4, green: 0.6, blue: 0.4), lineWidth: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(.horizontal, 40)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
        MainView(isLoggedIn: .constant(true))
    }
}
