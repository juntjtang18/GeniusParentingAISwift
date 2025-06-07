import SwiftUI
import KeychainAccess

struct MainView: View {
    @Binding var isLoggedIn: Bool // Binding to control login state
    @State private var selectedTab: Int = 0 // For TabView navigation
    
    // 1. Add a StateObject for the HomeViewModel
    @StateObject private var homeViewModel = HomeViewModel()

    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    var body: some View {
        // Wrap the TabView in a NavigationView to allow navigation from lesson cards
        NavigationView {
            TabView(selection: $selectedTab) {
                // Home Tab
                VStack(spacing: 20) {
                    // Header with Title and Logo
                    HStack {
                        Image("gpa-logo") // Placeholder for logo
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

                            // 2. Replace the placeholder UI with the view model's data
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
                                            // Link to the course detail view
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

                        // Hot Topics Section (remains placeholder for now)
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

                        // Daily Tips Section (remains placeholder for now)
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
                // 3. Call the fetch function when the view appears
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

                // AI Tab (Placeholder)
                VStack {
                    Text("AI View")
                        .font(.title)
                        .padding()
                    Spacer()
                }
                .tabItem {
                    Image(systemName: "brain.fill")
                    Text("AI")
                }
                .tag(2)

                // Community Tab (Placeholder)
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

                // Profile Tab (With Logout)
                VStack {
                    Text("Profile")
                        .font(.title)
                        .padding()
                    Button("Logout") {
                        keychain["jwt"] = nil
                        isLoggedIn = false
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    Spacer()
                }
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
            }
            .navigationTitle("Home")
            .navigationBarHidden(true) // Hides the title from the navigation bar
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(isLoggedIn: .constant(true))
    }
}
