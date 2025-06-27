import SwiftUI
import KeychainAccess

// MARK: - Image Caching System
class ImageCache {
    static let shared = NSCache<NSURL, UIImage>()
    private init() {}
}

@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let url: URL
    init(url: URL) { self.url = url }
    func load() {
        if let cachedImage = ImageCache.shared.object(forKey: url as NSURL) {
            self.image = cachedImage
            return
        }
        // Capture url locally to avoid accessing self.url in the closure
        let requestUrl = self.url
        URLSession.shared.dataTask(with: requestUrl) { data, response, error in
            guard let data = data, let loadedImage = UIImage(data: data), error == nil else { return }
            ImageCache.shared.setObject(loadedImage, forKey: requestUrl as NSURL)
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }.resume()
    }
}

struct CachedAsyncImage: View {
    @StateObject private var loader: ImageLoader
    init(url: URL) { _loader = StateObject(wrappedValue: ImageLoader(url: url)) }
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Color(UIColor.secondarySystemBackground)
            }
        }.onAppear { loader.load() }
    }
}

// MARK: - Course Card View
struct CourseCardView: View {
    let course: Course
    let selectedLanguage: String
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading) {
                let displayTitle = course.translations?[selectedLanguage]?.title ?? course.title
                Text(displayTitle).font(.headline).foregroundColor(.white).lineLimit(2).padding(8)
            }
        }
        .aspectRatio(16/7, contentMode: .fit)
        .background(
            Group {
                if let iconMedia = course.iconImageMedia, let imageUrl = URL(string: iconMedia.attributes.url) {
                    CachedAsyncImage(url: imageUrl)
                } else { Color(UIColor.secondarySystemBackground) }
            }
        )
        .cornerRadius(12)
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
    @StateObject private var viewModel = CourseViewModel()
    @Binding var selectedLanguage: String
    // FIXED: Add the binding to receive the side menu state.
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
        .navigationDestination(for: Int.self) { courseId in
            // FIXED: Pass the binding down to the detail view.
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
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")
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
            decoder.keyDecodingStrategy = .convertFromSnakeCase
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
        // 1. Guard against redundant fetches for the same category.
        guard coursesByCategoryID[categoryID] == nil, !loadingCategoryIDs.contains(categoryID) else {
            return
        }

        // 2. Set loading state and ensure it's removed on completion/exit.
        loadingCategoryIDs.insert(categoryID)
        defer { loadingCategoryIDs.remove(categoryID) }

        // 3. Ensure authentication token is available.
        guard let token = keychain["jwt"] else {
            print("Authentication token not found for fetching courses.")
            // Optionally, you could set an error message for the UI here.
            // self.errorMessage = "Authentication required."
            return
        }

        // 4. Initialize variables for pagination.
        var allCourses: [Course] = []
        var currentPage = 1
        var totalPages = 1
        let pageSize = 100 // Fetch up to 100 items per page for better performance.

        do {
            // 5. Loop until all pages for the category are fetched.
            repeat {
                let populateQuery = "populate=icon_image,translations"
                let filterQuery = "filters[coursecategory][id][$eq]=\(categoryID)"
                let paginationQuery = "pagination[page]=\(currentPage)&pagination[pageSize]=\(pageSize)"
                
                // 6. Safely construct the request URL.
                var urlComponents = URLComponents(string: "\(strapiUrl)/courses")
                urlComponents?.query = "\(populateQuery)&\(filterQuery)&\(paginationQuery)"

                guard let url = urlComponents?.url else {
                    print("Internal error: Invalid URL for fetching courses.")
                    break // Exit the loop if URL is invalid.
                }

                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Accept")

                // 7. Perform the network request.
                let (data, response) = try await URLSession.shared.data(for: request)

                // 8. Validate the HTTP response.
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("Server error \(statusCode) while fetching courses for category \(categoryID) on page \(currentPage).")
                    break // Exit loop on server error.
                }
                
                // 9. Decode the JSON response.
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedResponse = try decoder.decode(StrapiListResponse<Course>.self, from: data)

                // 10. Append the newly fetched courses to the master list.
                if let newCourses = decodedResponse.data {
                    allCourses.append(contentsOf: newCourses)
                }

                // 11. Get the total page count from the first successful response.
                if let pagination = decodedResponse.meta?.pagination {
                    totalPages = pagination.pageCount
                }
                
                // 12. Move to the next page.
                currentPage += 1

            } while currentPage <= totalPages

            // 13. Update the published dictionary with all fetched courses for the category.
            self.coursesByCategoryID[categoryID] = allCourses

        } catch {
            // 14. Handle any errors during the fetch or decoding process.
            print("Failed to fetch or decode courses for category \(categoryID): \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("Decoding error details: \(decodingError)")
            }
            // Optionally, set a user-facing error message.
            // self.errorMessage = "Failed to load courses for this category."
        }
    }
}
