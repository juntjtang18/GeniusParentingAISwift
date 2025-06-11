import SwiftUI
import KeychainAccess

struct MainView: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedTab: Int = 0

    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var courseViewModel = CourseViewModel()

    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Home Tab
                ScrollView { // Make the whole home screen scrollable
                    VStack(spacing: 30) { // Increased spacing
                        // Header with Title and Logo
                        HStack {
                            Image("gpa-logo")
                                .resizable()
                                .clipShape(Circle())
                                .frame(width: 45, height: 45)
                            Text("Genius Parenting AI")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Spacer() // Pushes title to the left
                        }
                        .padding(.horizontal)

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
                                            NavigationLink(destination: ShowACourseView(courseId: lesson.id)) {
                                                LessonCardView(lesson: lesson)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .frame(height: 150)
                            }
                        }

                        // --- UPDATED: Hot Topics Section ---
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
                                            // You can wrap this in a NavigationLink if you have a detail view for topics
                                            HotTopicCardView(topic: topic)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .frame(height: 150)
                            }
                        }

                        // --- UPDATED: Daily Tips Section ---
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
                                            // Each tip is displayed using the new card view.
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
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
                .onAppear {
                    print("MainView: Home tab .onAppear has been triggered.")
                    Task {
                        // Fetch all required data when the view appears
                        await homeViewModel.fetchDailyLessons()
                        await homeViewModel.fetchHotTopics()
                        await homeViewModel.fetchDailyTips() // Fetch daily tips
                    }
                }

                // Course Tab
                CourseView(viewModel: courseViewModel)
                    .tabItem { Image(systemName: "book.fill"); Text("Course") }
                    .tag(1)

                // AI Tab
                AIView()
                    .tabItem { Image(systemName: "brain.fill"); Text("AI") }
                    .tag(2)

                // Community Tab
                Text("Community View").font(.title).padding()
                    .tabItem { Image(systemName: "person.2.fill"); Text("Community") }
                    .tag(3)

                // Profile Tab
                ProfileView(isLoggedIn: $isLoggedIn, selectedTab: $selectedTab)
                    .tabItem { Image(systemName: "person.fill"); Text("Profile") }
                    .tag(4)
            }
            .navigationTitle(navigationTitle(for: selectedTab))
            .navigationBarHidden(selectedTab == 0) // Hide Nav bar only on Home
        }
    }
    
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(isLoggedIn: .constant(true))
    }
}
