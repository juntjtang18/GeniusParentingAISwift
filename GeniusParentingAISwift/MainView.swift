import SwiftUI
import KeychainAccess

struct MainView: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedTab: Int = 0
    
    // State management for sheets
    @State private var selectedLanguage = "en"
    @State private var isShowingLanguageSheet = false
    @State private var isShowingProfileSheet = false
    @State private var isShowingSettingSheet = false
    
    // State for the side menu
    @State private var isSideMenuShowing = false

    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var courseViewModel = CourseViewModel()

    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

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
            .sheet(isPresented: $isShowingLanguageSheet) {
                LanguagePickerView(selectedLanguage: $selectedLanguage)
            }
            .sheet(isPresented: $isShowingProfileSheet) {
                NavigationView {
                    ProfileView(isLoggedIn: $isLoggedIn)
                }
            }
            .sheet(isPresented: $isShowingSettingSheet) {
                NavigationView {
                    SettingView()
                }
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
            }

            HStack {
                Spacer()
                SideMenuView(
                    isShowing: $isSideMenuShowing,
                    isShowingProfileSheet: $isShowingProfileSheet,
                    isShowingLanguageSheet: $isShowingLanguageSheet,
                    isShowingSettingSheet: $isShowingSettingSheet
                )
                .frame(width: UIScreen.main.bounds.width * 0.7)
                .offset(x: isSideMenuShowing ? 0 : UIScreen.main.bounds.width)
            }
            .ignoresSafeArea()
        }
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
            HomeContentView(viewModel: homeViewModel, selectedLanguage: $selectedLanguage)
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { menuToolbar }
        }
        .navigationViewStyle(.stack) // FIX: Ensures correct layout on iPad
    }
    
    private var courseTab: some View {
        NavigationView {
            CourseView(viewModel: courseViewModel, selectedLanguage: $selectedLanguage)
                .navigationTitle("Courses")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { menuToolbar }
        }
        .navigationViewStyle(.stack) // FIX: Ensures correct layout on iPad
    }
    
    private var aiTab: some View {
        NavigationView {
            AIView()
                .navigationTitle("AI Assistant")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // FIX: Adds a custom back button to return to the Home tab
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            selectedTab = 0
                        }) {
                            Image(systemName: "chevron.left")
                            Text("Home")
                        }
                    }
                    // Your existing side menu button
                    menuToolbar
                }
        }
        .navigationViewStyle(.stack) // FIX: Ensures correct layout on iPad
    }
    
    private var communityTab: some View {
        // This view now calls the new CommunityView.
        CommunityView()
    }
}

struct HomeContentView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var selectedLanguage: String

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                todaysLessonSection
                hotTopicsSection
                dailyTipsSection
                Spacer()
            }
            .padding(.top)
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
                .font(.title2)
                .padding(.horizontal)

            Group {
                if viewModel.isLoading {
                    ProgressView().frame(height: 150)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundColor(.red).padding().frame(height: 150)
                } else if viewModel.todaysLessons.isEmpty {
                     Text("No lessons scheduled for today.").foregroundColor(.gray).padding().frame(height: 150)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.todaysLessons) { lesson in
                                NavigationLink(destination: ShowACourseView(selectedLanguage: $selectedLanguage, courseId: lesson.id)) {
                                    LessonCardView(lesson: lesson)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 150)
                }
            }
        }
    }
    
    private var hotTopicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hot Topics")
                .font(.title2)
                .padding(.horizontal)
            
            Group {
                if viewModel.isLoadingHotTopics {
                    ProgressView().frame(height: 150)
                } else if let errorMessage = viewModel.hotTopicsErrorMessage {
                    Text(errorMessage).foregroundColor(.red).padding().frame(height: 150)
                } else if viewModel.hotTopics.isEmpty {
                    Text("No hot topics available right now.").foregroundColor(.gray).padding().frame(height: 150)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.hotTopics) { topic in
                                HotTopicCardView(topic: topic)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 150)
                }
            }
        }
    }
    
    private var dailyTipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Tips")
                .font(.title2)
                .padding(.horizontal)

            Group {
                if viewModel.isLoadingDailyTips {
                    ProgressView().frame(height: 150)
                } else if let errorMessage = viewModel.dailyTipsErrorMessage {
                    Text(errorMessage).foregroundColor(.red).padding().frame(height: 150)
                } else if viewModel.dailyTips.isEmpty {
                    Text("No daily tips available right now.").foregroundColor(.gray).padding().frame(height: 150)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(viewModel.dailyTips) { tip in
                                DailyTipCardView(tip: tip)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 150)
                }
            }
        }
    }
}


// Language Picker View
struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Button("English") { selectedLanguage = "en"; dismiss() }
                Button("Spanish") { selectedLanguage = "es"; dismiss() }
            }
            .navigationTitle("Select Language")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
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
