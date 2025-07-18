// GeniusParentingAISwift/CourseListView.swift
import SwiftUI
import KeychainAccess

// MARK: - Course Card View
struct CourseCardView: View {
    @Environment(\.theme) var theme: Theme
    let course: Course
    let selectedLanguage: String
    private let cardHeight: CGFloat = 250

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top part: Image (3/5 of the height)
            Group {
                if let iconMedia = course.iconImageMedia, let imageUrl = URL(string: iconMedia.attributes.url) {
                    CachedAsyncImage(url: imageUrl)
                } else {
                    theme.cardBackground
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                }
            }
            .frame(height: cardHeight * 3 / 5)
            .frame(maxWidth: .infinity)
            .clipped()

            // Bottom part: Title and Play Button (2/5 of the height)
            HStack(alignment: .center) {
                let displayTitle = course.translations?[selectedLanguage]?.title ?? course.title
                Text(displayTitle)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Play Button
                ZStack {
                    Circle()
                        .fill(theme.accent)
                    Image(systemName: "play.fill")
                        .foregroundColor(theme.cardBackground)
                        .font(.system(size: 20))
                }
                .frame(width: 50, height: 50)
            }
            .frame(height: cardHeight * 2 / 5)
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
            .zIndex(1) // Prioritize header gestures
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
                                NavigationLink(value: course.id) {
                                    CourseCardView(course: course, selectedLanguage: selectedLanguage)
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                                .clipped()
                                .simultaneousGesture(TapGesture().onEnded {
                                    UserDefaults.standard.set(category.id, forKey: lastViewedCategoryKey)
                                })
                            }
                        } else if viewModel.loadingCategoryIDs.contains(category.id) {
                            HStack { Spacer(); ProgressView(); Spacer() }.frame(height: 100)
                        } else {
                            Color.clear.frame(height: 1)
                                .onAppear { Task { await viewModel.fetchCourses(for: category.id) } }
                        }
                    }
                    .padding(.top, 15)
                    .padding(.bottom, 20) // Separate from next category
                    .clipped()
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
            .zIndex(0) // Courses below header
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
                Text("No courses available.").foregroundColor(.gray)
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
        .background(theme.background.ignoresSafeArea())
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

// MARK: - Course View Model
@MainActor
class CourseViewModel: ObservableObject {
    @Published var categories: [CategoryData] = []
    @Published var coursesByCategoryID: [Int: [Course]] = [:]
    @Published var loadingCategoryIDs = Set<Int>()
    @Published var errorMessage: String? = nil
    var initialLoadCompleted = false

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: Config.keychainService)
    private let lastViewedCategoryKey = "lastViewedCategoryID"

    func initialFetch() async {
        guard !initialLoadCompleted else { return }
        
        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            return
        }
        
        let categoryQuery = "sort=order&populate=header_image"
        guard let url = URL(string: "\(strapiUrl)/coursecategories?\(categoryQuery)") else {
            errorMessage = "Internal error: Invalid URL."
            return
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(StrapiListResponse<CategoryData>.self, from: data)
            
            self.categories = decodedResponse.data ?? []
            self.initialLoadCompleted = true

            var priorityCategoryID: Int? = UserDefaults.standard.integer(forKey: lastViewedCategoryKey)
            if priorityCategoryID == 0 {
                priorityCategoryID = self.categories.first?.id
            }
            
            if let categoryID = priorityCategoryID {
                await fetchCourses(for: categoryID)
            }
        } catch {
            errorMessage = "Failed to fetch categories: \(error.localizedDescription)"
        }
    }

    func fetchCourses(for categoryID: Int) async {
        // ... (rest of the function is unchanged)
        guard coursesByCategoryID[categoryID] == nil, !loadingCategoryIDs.contains(categoryID) else {
            return
        }

        loadingCategoryIDs.insert(categoryID)
        defer { loadingCategoryIDs.remove(categoryID) }

        guard let token = keychain["jwt"] else {
            print("Authentication token not found for fetching courses.")
            return
        }

        var allCourses: [Course] = []
        var currentPage = 1
        var totalPages = 1
        let pageSize = 100

        do {
            repeat {
                let populateQuery = "populate=icon_image,translations"
                let filterQuery = "filters[coursecategory][id][$eq]=\(categoryID)"
                let sortQuery = "sort[0]=order:asc&sort[1]=title:asc"
                let paginationQuery = "pagination[page]=\(currentPage)&pagination[pageSize]=\(pageSize)"
                
                var urlComponents = URLComponents(string: "\(strapiUrl)/courses")
                urlComponents?.query = "\(populateQuery)&\(filterQuery)&\(sortQuery)&\(paginationQuery)"

                guard let url = urlComponents?.url else {
                    print("Internal error: Invalid URL for fetching courses.")
                    break
                }

                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Accept")

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("Server error \(statusCode) while fetching courses for category \(categoryID) on page \(currentPage).")
                    break
                }
                
                let decoder = JSONDecoder()
                let decodedResponse = try decoder.decode(StrapiListResponse<Course>.self, from: data)

                if let newCourses = decodedResponse.data {
                    allCourses.append(contentsOf: newCourses)
                }

                if let pagination = decodedResponse.meta?.pagination {
                    totalPages = pagination.pageCount
                }
                
                currentPage += 1

            } while currentPage <= totalPages

            self.coursesByCategoryID[categoryID] = allCourses

        } catch {
            print("Failed to fetch or decode courses for category \(categoryID): \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("Decoding error details: \(decodingError)")
            }
        }
    }
}
