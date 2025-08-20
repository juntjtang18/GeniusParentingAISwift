// GeniusParentingAISwift/Courses/CourseListView.swift
import SwiftUI
import KeychainAccess

// MARK: - Course Card View
struct CourseCardView: View {
    @Environment(\.theme) var theme: Theme
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
                        theme.background
                            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                    }
                }
                .frame(height: cardHeight * 0.7)
                .frame(maxWidth: .infinity)
                .clipped()

                // Add a lock icon overlay if the course is restricted.
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
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
                        .fill(isLocked ? .gray : theme.accent) // Use gray color for locked courses.
                    Image(systemName: "play.fill")
                        .foregroundColor(theme.background)
                        .font(.system(size: 20))
                }
                .frame(width: 50, height: 50)
            }
            .frame(height: cardHeight * 0.3)
            .style(.courseCard)
        }
        .frame(height: cardHeight)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .clipped()
    }
}


// MARK: - Collapsible Category View
struct CollapsibleCategoryView: View {
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
            .background(Color.secondary)
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

// MARK: - Main Course List View
struct CourseView: View {
    @Environment(\.theme) var theme: Theme
    @StateObject private var viewModel = CourseViewModel()
    @Binding var selectedLanguage: String
    @Binding var isSideMenuShowing: Bool

    var body: some View {
        VStack {
            if !viewModel.initialLoadCompleted && viewModel.categories.isEmpty {
                ProgressView("Loading Categories...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 15) {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red).multilineTextAlignment(.center).padding(.horizontal)
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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 25) {
                        ForEach(viewModel.categories) { category in
                            CollapsibleCategoryView(
                                category: category,
                                viewModel: viewModel,
                                selectedLanguage: $selectedLanguage
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Image("background1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
        .navigationDestination(for: Int.self) { courseId in
            ShowACourseView(selectedLanguage: $selectedLanguage, courseId: courseId, isSideMenuShowing: $isSideMenuShowing)
        }
        .onAppear {
            Task {
                await viewModel.initialFetch()
            }
        }
    }
}
