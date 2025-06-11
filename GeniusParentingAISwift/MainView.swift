import SwiftUI
import KeychainAccess

struct MainView: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedTab: Int = 0
    
    // State management for sheets
    @State private var selectedLanguage = "en"
    @State private var isShowingLanguageSheet = false
    @State private var isShowingProfileSheet = false // New state for profile
    
    // State for the side menu
    @State private var isSideMenuShowing = false

    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var courseViewModel = CourseViewModel()

    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    var body: some View {
        ZStack {
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

                    // The Profile Tab has been removed from the TabView
                }
                .navigationTitle(navigationTitle(for: selectedTab))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
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
                // New sheet for presenting the ProfileView
                .sheet(isPresented: $isShowingProfileSheet) {
                    NavigationView {
                        ProfileView(isLoggedIn: $isLoggedIn)
                    }
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
                    isShowingLanguageSheet: $isShowingLanguageSheet
                )
                .frame(width: UIScreen.main.bounds.width * 0.7)
                .offset(x: isSideMenuShowing ? 0 : UIScreen.main.bounds.width)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Tab Views
    
    private var homeTab: some View {
        ScrollView {
            VStack(spacing: 30) {
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
    
    // The profileTab computed property has been removed
    
    // MARK: - Helper Functions
    
    private func navigationTitle(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "Courses"
        case 2: return "AI Assistant"
        case 3: return "Community"
        // Case 4 for "Profile" is no longer needed
        default: return ""
        }
    }
}

// Language Picker View (no changes)
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
