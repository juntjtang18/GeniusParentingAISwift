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
    
    // ** CHANGE 1 of 4: Add state to control the popup **
    @State private var selectedTip: Tip? = nil

    var body: some View {
        // ** CHANGE 2 of 4: Wrap the content in a ZStack to layer the popup on top **
        ZStack {
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
            
            // ** CHANGE 3 of 4: Add the popup view layer. It only appears when a tip is selected. **
            if let tip = selectedTip {
                FairyTipPopupView(tip: tip, isPresented: Binding(
                    get: { selectedTip != nil },
                    set: { if !$0 { withAnimation(.spring()) { selectedTip = nil } } }
                ))
                .zIndex(1) // Ensure popup is on top
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
                                NavigationLink(destination: ShowACourseView(selectedLanguage: $selectedLanguage, courseId: lesson.id, isSideMenuShowing: $isSideMenuShowing)) {
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
                                // MODIFICATION: Pass the isSideMenuShowing binding
                                NavigationLink(destination: TopicView(selectedLanguage: $selectedLanguage, topicId: topic.id, isSideMenuShowing: $isSideMenuShowing)) {
                                    HotTopicCardView(topic: topic)
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
                                    .contentShape(Rectangle()) // Ensure tappable area
                                    .simultaneousGesture(
                                        TapGesture()
                                            .onEnded {
                                                print("Tapped DailyTipCardView: \(tip.text)") // Debug log
                                                withAnimation(.spring()) {
                                                    self.selectedTip = tip
                                                }
                                            }
                                    )
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

// MARK: - New View for the Fairy Popup
// This is the only new struct being added.
struct FairyTipPopupView: View {
    let tip: Tip
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // REFINED: Changed the blur material for a different, less intense effect.
            Rectangle()
                .fill(.clear)
                .background(.thinMaterial)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            ZStack(alignment: .top) {
                // The fairy image is now drawn first, so it appears behind the popup window.
                Image("fairy01")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220)
                    // REFINED: Moved fairy up by 5 points.
                    .offset(x: -180, y: -77)

                // The main content box of the popup.
                VStack(spacing: 0) {
                    // This ZStack contains the image and is kept at a fixed height.
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
                    .frame(height: 200) // Image container height remains unchanged.
                    .clipped()

                    // This ScrollView contains the text and can now expand.
                    ScrollView {
                        Text(tip.text)
                            .font(.body)
                            .foregroundColor(.secondary)
                            // REFINED: Text aligned to the left.
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    
                    Spacer() // Pushes the button to the bottom.

                    Button("Got it!") { isPresented = false }
                        .font(.headline)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                        .foregroundColor(.black.opacity(0.7))
                }
                // REFINED: Increased the total height of the popup window by 60.
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
