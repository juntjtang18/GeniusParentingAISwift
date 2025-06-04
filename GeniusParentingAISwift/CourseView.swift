import SwiftUI
import KeychainAccess

struct CourseView: View {
    @StateObject private var viewModel = CourseViewModel()
    @State private var selectedLanguage: String = "en"

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .navigationTitle("Courses")
                } else if viewModel.courses.isEmpty {
                    Text("No courses available")
                        .foregroundColor(.gray)
                        .navigationTitle("Courses")
                } else {
                    List(viewModel.courses) { course in
                        let displayTitle = course.translations?[selectedLanguage]?.title ?? course.title
                        NavigationLink(destination: ShowACourseView(courseId: course.id)) {
                            Text(displayTitle)
                                .font(.headline)
                        }
                    }
                    .navigationTitle("Courses")
                    .toolbar {
                        Picker("Language", selection: $selectedLanguage) {
                            Text("English").tag("en")
                            Text("Spanish").tag("es")
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchCourses()
        }
    }
}

@MainActor
class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading: Bool = true // Set to true initially
    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    func fetchCourses() async {
        isLoading = true // Ensure isLoading is true at the start of the fetch
        print("Starting fetchCourses")
        guard let token = keychain["jwt"] else {
            print("No JWT token found in Keychain")
            isLoading = false
            return
        }
        print("Using JWT token: \(token)")

        // Ensure your populate query is correct for all necessary fields, including translations if needed deeply.
        // Strapi v4 syntax for populating nested components and translations:
        // ?populate[content]=*&populate[translations]=*
        // If translations is a simple JSON field and not a relation, your current populate is fine.
        // The schema indicates 'translations: { type: 'json' }', so `populate[content]=*` should be sufficient
        // unless translations itself contains relations that need populating.
        let urlString = "\(strapiUrl)/courses?populate[content]=*" // Or more complex populating if needed for translations' content.
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            isLoading = false
            return
        }
        
        print("Request URL: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept") // Good practice to add Accept header

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("Status code: \(httpResponse.statusCode)")
                if let dataString = String(data: data, encoding: .utf8) {
                    // For debugging, print the raw response, especially if decoding fails
                    print("Response data string: \(dataString)")
                }
            }

            // Check for non-200 status codes before attempting to decode
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("Error: HTTP status code \(statusCode)")
                // You might want to parse error messages from Strapi here if available in `data`
                isLoading = false
                return
            }

            let decoder = JSONDecoder()
            // The keyDecodingStrategy is useful if Strapi returns snake_case keys (e.g., "created_at")
            // and your Swift properties are camelCase (e.g., "createdAt").
            // Your current Strapi schema uses camelCase for attributes, so this might not be strictly necessary
            // for those fields, but it doesn't hurt.
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let decodedResponse = try decoder.decode(CoursesResponse.self, from: data)
            print("Successfully decoded CoursesResponse.")
            // The print statement below might be too verbose if courses have a lot of content.
            // Consider printing `decodedResponse.data.count` or titles.
            // print("Fetched courses attributes: \(decodedResponse.data.map { $0.title })")
            
            self.courses = decodedResponse.data
        } catch {
            // More detailed error logging
            print("Error fetching or decoding courses: \(error)")
            if let decodingError = error as? DecodingError {
                print("Decoding error details: \(decodingError)")
            }
        }
        isLoading = false // Ensure isLoading is set to false after fetch completes or fails
    }

    // This struct correctly expects a "data" key at the root of the JSON response,
    // which contains an array of Course objects.
    struct CoursesResponse: Codable {
        let data: [Course]
    }
}
