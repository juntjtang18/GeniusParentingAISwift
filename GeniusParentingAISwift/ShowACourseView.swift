import SwiftUI
import KeychainAccess // For ShowACourseViewModel

// Assume Config, Course, Content, CourseTranslation structs are defined elsewhere
// e.g., in a Models.swift file or individual model files.

struct ShowACourseView: View {
    @StateObject private var viewModel = ShowACourseViewModel()
    @State private var selectedLanguage: String = "en" // Default language
    let courseId: Int
    @State private var currentPageIndex = 0 // For TabView pagination

    var body: some View {
        VStack(spacing: 0) {
            if let course = viewModel.course {
                let displayTitle = course.translations?[selectedLanguage]?.title ?? course.title
                
                // Header outside the TabView
                HStack {
                    Image(systemName: "book.fill") // Placeholder icon
                        .resizable()
                        .frame(width: 30, height: 30)
                    Text(displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer() // Push title to the left
                }
                .padding()

                let pages = groupContentIntoPages(content: course.content ?? [])

                if !pages.isEmpty {
                    TabView(selection: $currentPageIndex) {
                        ForEach(pages.indices, id: \.self) { pageIndex in // Iterate by page index
                            let pageContent = pages[pageIndex]
                            ScrollView { // Each page can scroll independently
                                VStack(alignment: .leading, spacing: 10) {
                                    // Iterate by item index within the page to ensure unique IDs for ForEach
                                    ForEach(pageContent.indices, id: \.self) { itemIndex in
                                        let item = pageContent[itemIndex]
                                        ContentParentView(content: item, language: selectedLanguage)
                                    }
                                }
                                .padding()
                            }
                            .tag(pageIndex) // Tag for TabView selection
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic)) // Enables swipeable pages with dots
                    .animation(.easeInOut, value: currentPageIndex) // Smooth transition for page changes

                } else {
                    Text("No content available for this course.")
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                ProgressView("Loading Course...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Course Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Picker("Language", selection: $selectedLanguage) {
                Text("English").tag("en")
                Text("Spanish").tag("es")
            }
            .pickerStyle(.menu)
        }
        .task {
            await viewModel.fetchCourse(courseId: courseId)
        }
    }

    /// Groups course content items into pages based on "content.pagebreaker" components.
    func groupContentIntoPages(content: [Content]) -> [[Content]] {
        var pages: [[Content]] = []
        var currentPage: [Content] = []
        
        for item in content {
            if item.__component == "content.pagebreaker" {
                if !currentPage.isEmpty {
                    pages.append(currentPage)
                    currentPage = []
                }
            } else {
                currentPage.append(item)
            }
        }
        
        if !currentPage.isEmpty {
            pages.append(currentPage)
        }
        
        return pages
    }
}

@MainActor
class ShowACourseViewModel: ObservableObject {
    @Published var course: Course?
    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    func fetchCourse(courseId: Int) async {
        guard let token = keychain["jwt"] else {
            print("Error: No JWT token found in Keychain.")
            return
        }

        guard let url = URL(string: "\(strapiUrl)/courses/\(courseId)?populate[content]=*&populate[translations]=*") else {
            print("Error: Invalid URL for fetching course.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        print("Fetching course with ID: \(courseId) from URL: \(url)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("Fetch course response status code: \(httpResponse.statusCode)")
                if !(200...299).contains(httpResponse.statusCode) {
                    if let responseBody = String(data: data, encoding: .utf8) {
                        print("Error response body: \(responseBody)")
                    }
                    print("Error: Received HTTP \(httpResponse.statusCode) for course fetch.")
                    return
                }
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let decodedResponse = try decoder.decode(CourseResponse.self, from: data)
            self.course = decodedResponse.data
            print("Successfully fetched course: \(self.course?.title ?? "Unknown")")

        } catch {
            print("Error fetching/decoding course ID \(courseId): \(error)")
            if let decodingError = error as? DecodingError {
                 print("Decoding error details: \(decodingError)")
            }
        }
    }

    struct CourseResponse: Codable {
        let data: Course
    }
}

// Preview Provider for ShowACourseView
struct ShowACourseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ShowACourseView(courseId: 1)
        }
    }
}
