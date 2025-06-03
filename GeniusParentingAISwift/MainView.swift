import SwiftUI
import KeychainAccess

struct MainView: View {
    @State private var selectedTab: Int = 0 // For TabView navigation
    @State private var isLoggedIn: Bool = true // For navigation back to LoginView

    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift") // Updated service name

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Home Tab
                VStack(spacing: 20) {
                    // Header with Title and Logo
                    HStack {
                        Image(systemName: "star.fill") // Placeholder for logo, replace with your image asset
                            .resizable()
                            .frame(width: 30, height: 30)
                        Text("Genius Parenting AI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    .padding()

                    // Middle Content Areas
                    VStack(spacing: 20) {
                        // Today's Lesson
                        ZStack {
                            Image(systemName: "photo") // Replace with your image asset (e.g., "lessonImage")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                            VStack {
                                Text("Today's Lesson")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 10)
                                Spacer()
                            }
                        }
                        .frame(height: 150)

                        // Hot Topics
                        ZStack {
                            Image(systemName: "photo") // Replace with your image asset (e.g., "hotTopicsImage")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                            VStack {
                                Text("Hot Topics")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 10)
                                Text("No AI at Los Angeles")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 10)
                                Spacer()
                            }
                        }
                        .frame(height: 150)

                        // Daily Tips
                        ZStack {
                            Image(systemName: "photo") // Replace with your image asset (e.g., "dailyTipsImage")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                            VStack {
                                Text("Daily Tips")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 10)
                                Text("Understanding your child inside")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 10)
                                Spacer()
                            }
                        }
                        .frame(height: 150)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

                // Course Tab (Placeholder)
                VStack {
                    Text("Course View")
                        .font(.title)
                        .padding()
                    Spacer()
                }
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
                        // Clear JWT and navigate back to login
                        keychain["jwt"] = nil
                        isLoggedIn = false
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    Spacer()

                    // Navigate back to LoginView when logged out
                    NavigationLink(destination: LoginView(), isActive: $isLoggedIn) {
                        EmptyView()
                    }
                    .hidden()
                }
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
            }
            .navigationBarHidden(true)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
