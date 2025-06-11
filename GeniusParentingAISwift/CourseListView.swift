import SwiftUI
import KeychainAccess

// MARK: - Course List View & ViewModel

struct CourseView: View {
    @ObservedObject var viewModel: CourseViewModel
    @Binding var selectedLanguage: String

    var body: some View {
        VStack {
            if viewModel.isLoading && viewModel.courses.isEmpty {
                ProgressView("Loading Courses...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 15) {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task {
                            await viewModel.fetchCourses()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.courses.isEmpty {
                Text("No courses available.")
                    .foregroundColor(.gray)
            } else {
                List(viewModel.courses) { course in
                    let displayTitle = course.translations?[selectedLanguage]?.title ?? course.title
                    NavigationLink(destination: ShowACourseView(selectedLanguage: $selectedLanguage, courseId: course.id)) {
                        HStack {
                            if let iconMedia = course.iconImageMedia {
                                if let imageUrl = URL(string: iconMedia.attributes.url) {
                                    AsyncImage(url: imageUrl) { phase in
                                        switch phase {
                                        case .empty: ProgressView().frame(width: 40, height: 40)
                                        case .success(let image): image.resizable().aspectRatio(contentMode: .fill).frame(width: 40, height: 40).clipShape(Circle())
                                        case .failure: Image(systemName: "photo.circle.fill").resizable().scaledToFit().frame(width: 40, height: 40).foregroundColor(.gray)
                                        @unknown default: EmptyView().frame(width: 40, height: 40)
                                        }
                                    }
                                } else {
                                    Image(systemName: "exclamationmark.circle.fill").resizable().scaledToFit().frame(width: 40, height: 40).foregroundColor(.orange)
                                }
                            } else {
                                Image(systemName: "book.closed.circle").resizable().scaledToFit().frame(width: 40, height: 40).foregroundColor(.gray)
                            }
                            VStack(alignment: .leading) {
                                Text(displayTitle).font(.headline)
                                if let categoryName = course.category?.attributes.name {
                                    Text(categoryName).font(.caption).foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
        }
        // Modifier removed, as the parent NavigationView in MainView now controls this.
        .onAppear {
            Task {
                await viewModel.fetchCourses()
            }
        }
    }
}

@MainActor
class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    init() {}

    func fetchCourses() async {
        let isRefreshEnabled = UserDefaults.standard.bool(forKey: "isRefreshModeEnabled")
        guard isRefreshEnabled || self.courses.isEmpty else {
            print("CourseViewModel: Skipping fetch for courses, using cached data.")
            return
        }
        
        print("CourseViewModel: Fetching courses...")
        self.isLoading = true
        self.errorMessage = nil

        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."; isLoading = false; return
        }
        
        let populateQuery = "populate[icon_image][populate]=*&populate[category]=*&populate[content][populate]=*&populate=translations"
        guard let url = URL(string: "\(strapiUrl)/courses?\(populateQuery)") else {
            errorMessage = "Internal error: Invalid URL."; isLoading = false; return
        }
        var request = URLRequest(url: url); request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                var detailedError = "Server error \(statusCode)."
                if let errData = try? JSONDecoder().decode(StrapiErrorResponse.self, from: data) {
                    detailedError = errData.error.message
                }
                errorMessage = detailedError
                isLoading = false; return
            }
            let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(StrapiListResponse<Course>.self, from: data)
            self.courses = decodedResponse.data
        } catch {
            if let decError = error as? DecodingError {
                errorMessage = "Data parsing error: \(decError.localizedDescription)"
            } else {
                errorMessage = "Fetch error: \(error.localizedDescription)"
            }
        }
        isLoading = false
    }
}
