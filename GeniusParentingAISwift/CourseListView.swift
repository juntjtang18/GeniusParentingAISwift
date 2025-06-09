import SwiftUI
import KeychainAccess

// MARK: - Course List View & ViewModel

struct CourseView: View {
    // This viewModel is passed in from MainView and is now observed.
    @ObservedObject var viewModel: CourseViewModel
    @State private var selectedLanguage: String = "en"

    var body: some View {
        // This view is now simpler. It just displays the state of the ViewModel.
        // The .task modifier has been removed.
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Courses...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 15) {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task {
                            // The retry button still works by calling the function directly.
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
                    NavigationLink(destination: ShowACourseView(courseId: course.id)) {
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Picker("Language", selection: $selectedLanguage) {
                            Text("English").tag("en"); Text("Spanish").tag("es")
                        }.pickerStyle(.menu)
                    }
                }
            }
        }
        .navigationTitle("Courses")
    }
}

@MainActor
class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading: Bool = true // Start in a loading state
    @Published var errorMessage: String? = nil

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    // --- MODIFICATION START ---
    // The ViewModel now triggers its own data fetch upon initialization.
    init() {
        Task {
            await fetchCourses()
        }
    }
    // --- MODIFICATION END ---

    func fetchCourses() async {
        // Ensure state is correctly set for a new fetch or a retry
        self.isLoading = true
        self.errorMessage = nil

        print("Starting fetchCourses")
        guard let token = keychain["jwt"] else {
            print("No JWT token found in Keychain")
            errorMessage = "Authentication token not found."; isLoading = false; return
        }
        print("Using JWT token (first 10 chars): \(String(token.prefix(10)))...")

        let populateQuery = "populate[icon_image][populate]=*&populate[category]=*&populate[content][populate]=*&populate=translations"
        guard let url = URL(string: "\(strapiUrl)/courses?\(populateQuery)") else {
            print("Invalid URL construction for: \(strapiUrl)/courses?\(populateQuery)")
            errorMessage = "Internal error: Invalid URL."; isLoading = false; return
        }
        var request = URLRequest(url: url); request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        print("Fetching courses from: \(url.absoluteString)")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response from server.")
                errorMessage = "Invalid server response."; isLoading = false; return
            }
            print("Courses fetch status: \(httpResponse.statusCode)")
            guard (200...299).contains(httpResponse.statusCode) else {
                var detailedError = "Server error \(httpResponse.statusCode)."
                if let errData = try? JSONDecoder().decode(StrapiErrorResponse.self, from: data) {
                    detailedError = errData.error.message
                    print("Strapi error: \(errData.error.message) - \(errData.error.details ?? .null)")
                } else if let responseBody = String(data: data, encoding: .utf8) {
                    print("Error response body: \(responseBody)")
                }
                errorMessage = detailedError
                isLoading = false; return
            }
            let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(StrapiListResponse<Course>.self, from: data)
            print("Successfully decoded StrapiListResponse for courses.")
            self.courses = decodedResponse.data
        } catch {
            // Because the task is no longer tied to the view, we don't expect a cancellation
            // error from the UI, so any cancellation is likely real and should be reported.
            if let decError = error as? DecodingError {
                errorMessage = "Data parsing error: \(decError.localizedDescription)"
                print("Decoding error details: \(decError)")
            }
            else { errorMessage = "Fetch error: \(error.localizedDescription)" }
            print("Fetch courses error: \(error)")
        }
        isLoading = false
    }
}
