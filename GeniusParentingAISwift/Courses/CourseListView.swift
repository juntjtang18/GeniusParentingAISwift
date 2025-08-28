// GeniusParentingAISwift/Courses/CourseListView.swift
import SwiftUI
import KeychainAccess

// MARK: - Course Card View
struct CourseCardView: View {
    @Environment(\.theme) var currentTheme: Theme
    let course: Course
    let selectedLanguage: String
    private let cardHeight: CGFloat = 250

    // Determine if the course is locked for the current user.
    private var isLocked: Bool {
        // A course is locked if it's membership-only AND the user doesn't have access.
        return course.isMembershipOnly && !PermissionManager.shared.canAccess(.accessMembershipCourses)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top part: Image (70% of the height)
            ZStack(alignment: .topLeading) { // Use a ZStack to overlay the lock icon.
                Group {
                    if let iconMedia = course.iconImageMedia, let imageUrl = URL(string: iconMedia.attributes.url) {
                        CachedAsyncImage(url: imageUrl)
                    } else {
                        currentTheme.background
                            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                    }
                }
                .frame(height: cardHeight * 0.7)
                .background(currentTheme.background)
                .frame(maxWidth: .infinity)
                .clipped()

                // Add a lock icon overlay if the course is restricted.
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(currentTheme.accent)
                        .padding(8)
                        .background(currentTheme.accentBackground.opacity(0.5))
                        .clipShape(Circle())
                        .padding(10)
                }
            }

            // Bottom part: Title and Play Button (30% of the height)
            HStack(alignment: .center) {
                let displayTitle = course.translations?[selectedLanguage]?.title ?? course.title
                Text(displayTitle)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Play Button
                ZStack {
                    Circle()
                        .fill(isLocked ? .gray : currentTheme.background) // Use gray color for locked courses.
                    Image(systemName: "play.fill")
                        .foregroundColor(currentTheme.foreground)
                        .font(.system(size: 20))
                }
                .frame(width: 50, height: 50)
            }
            .frame(height: cardHeight * 0.3)
            .style(.courseCard)
        }
        .background(currentTheme.accentBackground)
        .frame(height: cardHeight)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .clipped()
    }
}


// MARK: - Collapsible Category View
struct CollapsibleCategoryView: View {
    @Environment(\.theme) var currentTheme: Theme
    let category: CategoryData
    @ObservedObject var viewModel: CourseViewModel
    @Binding var selectedLanguage: String
    @State private var isExpanded: Bool = true
    
    // State to manage the alert and the subsequent sheet presentation.
    @State private var showPermissionAlert = false
    @State private var showSubscriptionSheet = false

    private let lastViewedCategoryKey = "lastViewedCategoryID"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            ZStack {
                if let headerMedia = category.attributes.header_image?.data,
                   let imageUrl = URL(string: headerMedia.attributes.url) {
                    CachedAsyncImage(url: imageUrl).aspectRatio(contentMode: .fill)
                } else {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                LinearGradient(gradient: Gradient(colors: [.black.opacity(0.6), .clear, .black.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                HStack {
                    Text(category.attributes.name)
                        .font(.title2).fontWeight(.bold).foregroundColor(.white).shadow(radius: 2)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.title3.weight(.medium)).foregroundColor(.white.opacity(0.8))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .padding()
            }
            .frame(height: 80)
            .background(currentTheme.background)
            .cornerRadius(15)
            .contentShape(Rectangle())
            .clipped()
            .zIndex(1)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }

            // Courses
            Group {
                if isExpanded {
                    LazyVStack(spacing: 15) {
                        if let courses = viewModel.coursesByCategoryID[category.id] {
                            ForEach(courses) { course in
                                // Determine if the course is locked for the current user.
                                let isLocked = course.isMembershipOnly && !PermissionManager.shared.canAccess(.accessMembershipCourses)

                                if isLocked {
                                    // If the course is locked, display it as a Button that triggers an alert.
                                    Button(action: {
                                        self.showPermissionAlert = true
                                    }) {
                                        CourseCardView(course: course, selectedLanguage: selectedLanguage)
                                    }
                                } else {
                                    // If the course is accessible, display it as a NavigationLink.
                                    NavigationLink(destination: ShowACourseView(selectedLanguage: $selectedLanguage, courseId: course.id, isSideMenuShowing: .constant(false))) {
                                        CourseCardView(course: course, selectedLanguage: selectedLanguage)
                                    }
                                    .simultaneousGesture(TapGesture().onEnded {
                                         UserDefaults.standard.set(category.id, forKey: lastViewedCategoryKey)
                                     })
                                }
                            }
                        } else if viewModel.loadingCategoryIDs.contains(category.id) {
                            HStack { Spacer(); ProgressView(); Spacer() }.frame(height: 100)
                        } else {
                            Color.clear.frame(height: 1)
                                .onAppear { Task { await viewModel.fetchCourses(for: category.id) } }
                        }
                    }
                    .padding(.top, 15)
                    .padding(.bottom, 20)
                    .clipped()
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
            .zIndex(0)
        }
        .buttonStyle(.plain) // Ensures the buttons don't have default styling.
        .alert("Membership Required", isPresented: $showPermissionAlert) {
            Button("Subscribe") {
                // When the user taps "Subscribe", trigger the subscription sheet to show.
                self.showSubscriptionSheet = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The course is accessible only by member. Subscribe membership plan to gain full access.")
        }
        .fullScreenCover(isPresented: $showSubscriptionSheet) {
            // This sheet is presented when the user confirms they want to subscribe.
            //SubscriptionView(isPresented: $showSubscriptionSheet, recommendedPlanTier: .basic)
            SubscriptionView(isPresented: $showSubscriptionSheet)

        }
    }
}

// MARK: - Main Course List View (refactored for picker + category list)
struct CourseView: View {
    @Environment(\.theme) var theme: Theme
    @StateObject private var viewModel = CourseViewModel()
    @Binding var selectedLanguage: String
    @Binding var isSideMenuShowing: Bool

    @State private var selectedCategory: CategoryData? = nil

    var body: some View {
        Group {
            if !viewModel.initialLoadCompleted && viewModel.categories.isEmpty {
                ProgressView("Loading Categories...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 15) {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task {
                            viewModel.initialLoadCompleted = false
                            await viewModel.initialFetch()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.categories.isEmpty {
                Text("No courses available.")
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            } else {
                // Two modes: picker vs list
                if let cat = selectedCategory {
                    CategoryListScreen(
                        category: cat,
                        viewModel: viewModel,
                        selectedLanguage: $selectedLanguage,
                        onBack: { withAnimation { selectedCategory = nil } }
                    )
                } else {
                    CategoryPickerScreen(
                        categories: viewModel.categories,
                        onPick: { category in
                            withAnimation { selectedCategory = category }
                            Task { await viewModel.fetchCourses(for: category.id) }
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .navigationDestination(for: Int.self) { courseId in
            ShowACourseView(
                selectedLanguage: $selectedLanguage,
                courseId: courseId,
                isSideMenuShowing: $isSideMenuShowing
            )
        }
        .onAppear {
            Task { await viewModel.initialFetch() }
        }
    }
}


// MARK: - Picker Screen (blue header + hero image + blue section with tiles)
private struct CategoryPickerScreen: View {
    @Environment(\.theme) var currentTheme: Theme
    let categories: [CategoryData]
    let onPick: (CategoryData) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top blue banner
                VStack(alignment: .leading, spacing: 6) {
                    (
                        Text("GenParenting ")
                            .font(.title2).bold()
                            .foregroundColor(currentTheme.foreground)
                        +
                        Text("Courses")
                            .font(.title2).bold()
                            .foregroundColor(currentTheme.foreground)
                    )

                    Text("Simple guidance every step of the way.")
                        .font(.callout)
                        .foregroundColor(currentTheme.foreground.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 18)
                .background(currentTheme.background)

                // Hero image — full width, no rounded corners, no overlap
                Image("family")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()                 // crop overflow but keep square corners
                    .padding(.bottom, 12)      // space before tiles

                // Blue section containing white rounded tiles
                VStack(spacing: 14) {
                    ForEach(categories) { cat in
                        CategoryTileButton(category: cat) { onPick(cat) }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 15)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 27/255, green: 74/255, blue: 175/255))


                Spacer(minLength: 20)
            }
        }
    }
}



private struct CategoryTileButton: View {
    @Environment(\.theme) var currentTheme: Theme

    let category: CategoryData
    let action: () -> Void

    // Pick asset image based on index or name.
    // Adjust mapping logic as you like.
    private var leadingImageName: String {
        switch category.attributes.name.lowercased() {
        case let n where n.contains("foundation"):
            return "course-category1"
        case let n where n.contains("member"):
            return "course-category2"
        case let n where n.contains("tool"):
            return "course-category3"
        default:
            return "course-category1"
        }
    }

    // Simple subtitle placeholder (replace with real field if available)
    private var subtitleText: String {
        switch category.attributes.name.lowercased() {
        case let n where n.contains("foundation"):
            return "Easy steps to guide parents through"
        case let n where n.contains("member"):
            return "Unlock exclusive courses"
        case let n where n.contains("tool"):
            return "Everything parents need, in one place"
        default:
            return "Tap to explore"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {

                // Left icon block from asset
                Image(leadingImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Title + subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.attributes.name)
                        .font(.headline)
                        .foregroundColor(currentTheme.accent)
                        .lineLimit(1)

                    Text(subtitleText)
                        .font(.subheadline)
                        .foregroundColor(currentTheme.accent)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(16)
            .background(currentTheme.accentBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}



// MARK: - Category List Screen (courses of selected category)
private struct CategoryListScreen: View {
    @Environment(\.theme) var currentTheme: Theme
    let category: CategoryData
    @ObservedObject var viewModel: CourseViewModel
    @Binding var selectedLanguage: String
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Category title
                Text(category.attributes.name)
                    .font(.title3).bold()
                    .foregroundColor(currentTheme.foreground)
                    .padding(.top, 4)

                // Courses list
                Group {
                    if let courses = viewModel.coursesByCategoryID[category.id] {
                        LazyVStack(spacing: 18) {
                            ForEach(courses) { course in
                                NavigationLink(
                                    destination: ShowACourseView(
                                        selectedLanguage: $selectedLanguage,
                                        courseId: course.id,
                                        isSideMenuShowing: .constant(false)
                                    )
                                ) {
                                    CourseCardView(course: course, selectedLanguage: selectedLanguage)
                                }
                            }
                        }
                    } else if viewModel.loadingCategoryIDs.contains(category.id) {
                        HStack { Spacer(); ProgressView(); Spacer() }
                            .frame(height: 120)
                    } else {
                        Color.clear.frame(height: 1)
                            .onAppear {
                                Task { await viewModel.fetchCourses(for: category.id) }
                            }
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle(category.attributes.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // keep your existing leading back
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Courses")
                    }
                }
            }
            // keep your existing trailing items (refresh/menu) here...
        }
        .tint(currentTheme.accent) // buttons adopt theme color (iOS 15+)
        /*
        .onAppear {
            // Title color via UINavigationBarAppearance
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            //appearance.backgroundColor = .clear
            appearance.backgroundColor = UIColor(currentTheme.background)

            // Convert SwiftUI.Color -> UIColor safely
            let titleColor = UIColor(currentTheme.foreground)
            appearance.titleTextAttributes = [.foregroundColor: titleColor]
            appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

            // Apply
            let navBar = UINavigationBar.appearance()
            navBar.standardAppearance = appearance
            navBar.compactAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
        }
        .onDisappear {
            // (Optional) reset to system default when leaving this screen
            let reset = UINavigationBarAppearance()
            reset.configureWithDefaultBackground()
            UINavigationBar.appearance().standardAppearance = reset
            UINavigationBar.appearance().compactAppearance = reset
            UINavigationBar.appearance().scrollEdgeAppearance = reset
        }
         */
    }
}

