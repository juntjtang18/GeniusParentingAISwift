// MainView.swift

import SwiftUI
import KeychainAccess

struct MainView: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedTab: Int = 0
    
    @StateObject private var homeViewModel = HomeViewModel()

    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Home Tab
                VStack(spacing: 20) {
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
                    }
                    .padding()

                    // Middle Content Areas
                    VStack(spacing: 20) {
                        // Today's Lesson Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Today's Lesson")
                                .font(.title2)
                                .padding(.horizontal)

                            if homeViewModel.isLoading {
                                ProgressView()
                                    .frame(height: 150)
                            } else if let errorMessage = homeViewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .padding()
                                    .frame(height: 150)
                            } else if homeViewModel.todaysLessons.isEmpty {
                                 Text("No lessons scheduled for today.")
                                     .foregroundColor(.gray)
                                     .padding()
                                     .frame(height: 150)
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

                        // Hot Topics Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Hot Topics")
                                .font(.title2)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(0..<3) { _ in
                                        ZStack {
                                            Image("hotTopicsImage")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 250, height: 150)
                                                .clipped()
                                                .cornerRadius(10)
                                            Text("No AI at Los Angeles")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .padding(.bottom, 10)
                                        }
                                        .frame(width: 250, height: 150)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 150)
                        }

                        // Daily Tips Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Daily Tips")
                                .font(.title2)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(0..<3) { _ in
                                        ZStack {
                                            Image("dailyTipsImage")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 250, height: 150)
                                                .clipped()
                                                .cornerRadius(10)
                                            Text("Understanding your child inside")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .padding(.bottom, 10)
                                        }
                                        .frame(width: 250, height: 150)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 150)
                        }
                    }

                    Spacer()
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
                .onAppear {
                    print("MainView: Home tab .onAppear has been triggered.")
                    Task {
                        await homeViewModel.fetchDailyLessons()
                    }
                }

                // Course Tab
                CourseView()
                    .tabItem {
                        Image(systemName: "book.fill")
                        Text("Course")
                    }
                    .tag(1)

                // AI Tab
                AIView()
                    .tabItem {
                        Image(systemName: "brain.fill")
                        Text("AI")
                    }
                    .tag(2)
                
                // Community Tab
                VStack {
                    Text("Community View")
                        .font(.title)
                        .padding()
                    Spacer()
                }
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Community")
                }
                .tag(3)

                // --- MODIFICATION START ---
                // Replace the old VStack with the new ProfileView
                ProfileView(isLoggedIn: $isLoggedIn)
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(4)
                // --- MODIFICATION END ---
            }
            // --- MODIFICATION START ---
            // Set the navigation title based on the selected tab
            .navigationTitle(navigationTitle(for: selectedTab))
            // Hide the navigation bar only for the Home tab (tag 0)
            .navigationBarHidden(selectedTab == 0)
            // --- MODIFICATION END ---
        }
    }
    
    // --- MODIFICATION START ---
    // Helper function to determine the navigation title for each tab
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
    // --- MODIFICATION END ---
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(isLoggedIn: .constant(true))
    }
}
