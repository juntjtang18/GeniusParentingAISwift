// GeniusParentingAISwift/Courses/CourseListView.swift
import SwiftUI
import KeychainAccess

// MARK: - Course Card View
struct CourseCardView: View {
    @Environment(\.theme) var currentTheme: Theme
    @EnvironmentObject var permissionManager: PermissionManager
    let course: Course
    let selectedLanguage: String
    private let cardHeight: CGFloat = 250

    // Determine if the course is locked for the current user.
    private var isLocked: Bool {
        // A course is locked if it's membership-only AND the user doesn't have access.
        return course.isMembershipOnly && !permissionManager.canAccess(.accessMembershipCourses)
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

                PlayButtonView(isLocked: isLocked);
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


/*
// MARK: - Collapsible Category View
struct CollapsibleCategoryView: View {
    @Environment(\.theme) var currentTheme: Theme
    @EnvironmentObject var permissionManager: PermissionManager
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
                    // Use theme gradient for the header if no image
                    Rectangle().fill(LinearGradient(colors: [currentTheme.background, currentTheme.background2], startPoint: .topLeading, endPoint: .bottomTrailing))
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
            .background(Color.clear) // Changed to clear to let background gradient show
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
                                // --- Start of Debugging Logic ---

                                // ✅ Use the reactive manager from the environment
                                let hasAccess = permissionManager.canAccess(.accessMembershipCourses)
                                let isLocked = course.isMembershipOnly && !hasAccess

                                // ✅ Add the log you requested
                                let _ = print("""
                                --- Checking Course: \(course.title) ---
                                Is Membership Only: \(course.isMembershipOnly)
                                User Has Access to Membership Courses: \(hasAccess)
                                Result -> Is Locked: \(isLocked)
                                --------------------
                                """)
                                
                                // --- End of Debugging Logic ---
                                // Determine if the course is locked for the current user.
                                //let isLocked = course.isMembershipOnly && !PermissionManager.shared.canAccess(.accessMembershipCourses)

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

 */
// MARK: - Main Course List View (refactored for picker + category list)
struct CourseView: View {
    @Environment(\.theme) var theme: Theme
    @StateObject private var viewModel = CourseViewModel()
    @Binding var selectedLanguage: String
    @Binding var isSideMenuShowing: Bool

    @State private var selectedCategory: CategoryData? = nil
    @EnvironmentObject private var tabRouter: MainTabRouter

    var body: some View {
        ZStack { // Added ZStack for the gradient background
            LinearGradient(
                colors: [theme.background, theme.background2],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
            // Removed .background(theme.background) here as gradient is now in ZStack
        }
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
        .onChange(of: tabRouter.needsCourseViewReset) { shouldReset in
            if shouldReset {
                selectedCategory = nil // Reset the state
                tabRouter.needsCourseViewReset = false // Consume the signal
            }
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
                // Top banner: Now uses theme gradient
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
                .background(LinearGradient(colors: [currentTheme.background, currentTheme.background2], startPoint: .top, endPoint: .bottom))


                // Hero image — full width, no rounded corners, no overlap
                Image("family")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()                 // crop overflow but keep square corners
                    .padding(.bottom, 12)      // space before tiles

                // Section containing white rounded tiles: Now uses theme gradient
                VStack(spacing: 14) {
                    ForEach(categories) { cat in
                        CategoryTileButton(category: cat) { onPick(cat) }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 15)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [currentTheme.background, currentTheme.background2], startPoint: .top, endPoint: .bottom))


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
    // 1. Receive the reactive PermissionManager from the environment
    @EnvironmentObject var permissionManager: PermissionManager
    
    // 2. Add state variables to control the alert and subscription sheet
    @State private var showPermissionAlert = false
    @State private var showSubscriptionSheet = false

    let category: CategoryData
    @ObservedObject var viewModel: CourseViewModel
    @Binding var selectedLanguage: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [currentTheme.background, currentTheme.background2],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(category.attributes.name)
                        .font(.title3).bold()
                        .foregroundColor(currentTheme.foreground)
                        .padding(.top, 4)

                    Group {
                        if let courses = viewModel.coursesByCategoryID[category.id] {
                            LazyVStack(spacing: 18) {
                                ForEach(courses) { course in
                                    // 3. This is the complete, migrated permission logic
                                    let hasAccess = permissionManager.canAccess(.accessMembershipCourses)
                                    let isLocked = course.isMembershipOnly && !hasAccess

                                    // 4. This log will now work correctly
                                    let _ = print("""
                                    --- [CategoryListScreen] Checking Course: \(course.title) ---
                                    Is Membership Only: \(course.isMembershipOnly)
                                    User Has Access: \(hasAccess)
                                    Result -> Is Locked: \(isLocked)
                                    --------------------
                                    """)

                                    if isLocked {
                                        Button(action: { self.showPermissionAlert = true }) {
                                            CourseCardView(course: course, selectedLanguage: selectedLanguage)
                                        }
                                    } else {
                                        NavigationLink(destination: ShowACourseView(selectedLanguage: $selectedLanguage, courseId: course.id, isSideMenuShowing: .constant(false))) {
                                            CourseCardView(course: course, selectedLanguage: selectedLanguage)
                                        }
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
        }
        .navigationTitle(category.attributes.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Courses")
                    }
                }
            }
        }
        // 5. Add the necessary modifiers to handle the alert and sheet
        .alert("Membership Required", isPresented: $showPermissionAlert) {
            Button("Subscribe") { self.showSubscriptionSheet = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This course requires a membership to access.")
        }
        .fullScreenCover(isPresented: $showSubscriptionSheet) {
            SubscriptionView(isPresented: $showSubscriptionSheet)
        }
    }
}
