import SwiftUI
import KeychainAccess

struct MainView: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedTab: Int = 0
    
    // Centralized state for language management
    @State private var selectedLanguage = "en"
    @State private var isShowingLanguageSheet = false
    
    // New state to control the side menu's visibility
    @State private var isSideMenuShowing = false

    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var courseViewModel = CourseViewModel()

    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    var body: some View {
        // ZStack is now the root view to layer the side menu over the main content
        ZStack {
            // --- Main Content ---
            NavigationView {
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

                    profileTab
                        .tabItem {
                            Image(systemName: "person.fill")
                            Text("Profile")
                        }
                        .tag(4)
                }
                .navigationTitle(navigationTitle(for: selectedTab))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        // This button now toggles the side menu
                        Button(action: {
                            withAnimation(.easeInOut) {
                                isSideMenuShowing.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                        }
                    }
                }
                .sheet(isPresented: $isShowingLanguageSheet) {
                    LanguagePickerView(selectedLanguage: $selectedLanguage)
                }
            }
            
            // --- Side Menu Layer ---
            
            // Dimming overlay that appears behind the menu
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

            // The Side Menu View itself, pushed to the right
            HStack {
                Spacer()
                SideMenuView(
                    isShowing: $isSideMenuShowing,
                    selectedTab: $selectedTab,
                    isShowingLanguageSheet: $isShowingLanguageSheet
                )
                .frame(width: UIScreen.main.bounds.width * 0.7) // 70% of screen width
                .offset(x: isSideMenuShowing ? 0 : UIScreen.main.bounds.width) // Animate offset
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Tab Views
    
    private var homeTab: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Today's Lesson Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Today's Lesson")
                        .font(.title2).bold()
                        .padding(.horizontal)

                    if homeViewModel.isLoading {
                        ProgressView().frame(height: 150)
                    } else if let errorMessage = homeViewModel.errorMessage {
                        Text(errorMessage).foregroundColor(.red).padding().frame(height: 150)
                    } else if homeViewModel.todaysLessons.isEmpty {
                         Text("No lessons scheduled for today.").foregroundColor(.gray).padding().frame(height: 150)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(homeViewModel.todaysLessons) { lesson in
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

                // Hot Topics Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hot Topics")
                        .font(.title2).bold()
                        .padding(.horizontal)
                    
                    if homeViewModel.isLoadingHotTopics {
                        ProgressView().frame(height: 150)
                    } else if let errorMessage = homeViewModel.hotTopicsErrorMessage {
                        Text(errorMessage).foregroundColor(.red).padding().frame(height: 150)
                    } else if homeViewModel.hotTopics.isEmpty {
                        Text("No hot topics available right now.").foregroundColor(.gray).padding().frame(height: 150)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(homeViewModel.hotTopics) { topic in
                                    HotTopicCardView(topic: topic)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 150)
                    }
                }

                // Daily Tips Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Daily Tips")
                        .font(.title2).bold()
                        .padding(.horizontal)

                    if homeViewModel.isLoadingDailyTips {
                        ProgressView().frame(height: 150)
                    } else if let errorMessage = homeViewModel.dailyTipsErrorMessage {
                        Text(errorMessage).foregroundColor(.red).padding().frame(height: 150)
                    } else if homeViewModel.dailyTips.isEmpty {
                        Text("No daily tips available right now.").foregroundColor(.gray).padding().frame(height: 150)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(homeViewModel.dailyTips) { tip in
                                    DailyTipCardView(tip: tip)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 150)
                    }
                }
                
                Spacer()
            }
            .padding(.top)
        }
        .onAppear {
            Task {
                await homeViewModel.fetchDailyLessons()
                await homeViewModel.fetchHotTopics()
                await homeViewModel.fetchDailyTips()
            }
        }
    }
    
    private var courseTab: some View {
        CourseView(viewModel: courseViewModel, selectedLanguage: $selectedLanguage)
    }
    
    private var aiTab: some View {
        AIView()
    }
    
    private var communityTab: some View {
        Text("Community View").font(.title).padding()
    }
    
    private var profileTab: some View {
        ProfileView(isLoggedIn: $isLoggedIn, selectedTab: $selectedTab)
    }
    
    // MARK: - Helper Functions
    
    private func navigationTitle(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "Courses"
        case 2: return "AI Assistant"
        case 3: return "Community"
        case 4: return "Profile"
        default: return ""
        }
    }
}

// --- Language Picker View is now here for central access ---
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
