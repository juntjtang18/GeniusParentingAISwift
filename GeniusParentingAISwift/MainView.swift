import SwiftUI
import KeychainAccess

struct MainView: View {
    @Binding var isLoggedIn: Bool // Binding to control login state
    @State private var selectedTab: Int = 0 // For TabView navigation

    let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            VStack(spacing: 20) {
                // Header with Title and Logo
                HStack {
                    Image(systemName: "star.fill") // Placeholder for logo
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
                    // Today's Lesson Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today's Lesson")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0..<3) { _ in // Placeholder for multiple lessons
                                    ZStack {
                                        Image("lessonImage") // Replace with your image asset
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 250, height: 150)
                                            .clipped()
                                            .cornerRadius(10)
                                        Text("Lesson Content")
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

                    // Hot Topics Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hot Topics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0..<3) { _ in // Placeholder for multiple topics
                                    ZStack {
                                        Image("hotTopicsImage") // Replace with your image asset
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
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0..<3) { _ in // Placeholder for multiple tips
                                    ZStack {
                                        Image("dailyTipsImage") // Replace with your image asset
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
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(isLoggedIn: .constant(true))
    }
}
