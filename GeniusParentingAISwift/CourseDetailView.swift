import SwiftUI
import KeychainAccess
import AVKit // For VideoPlayer

// MARK: - Single Course View & ViewModel

struct ShowACourseView: View {
    @StateObject private var viewModel = ShowACourseViewModel()
    @State private var selectedLanguage: String = "en"
    let courseId: Int
    @State private var currentPageIndex = 0
    @State private var showLanguagePicker = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView("Loading Course...").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                 Text("Error: \(errorMessage)").foregroundColor(.red).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let course = viewModel.course {
                let displayTitle = course.translations?[selectedLanguage]?.title ?? course.title
                HStack { // Header
                    if let iconMedia = course.iconImageMedia {
                        if let imgUrl = URL(string: iconMedia.attributes.url) {
                            AsyncImage(url: imgUrl) { phase in
                                switch phase {
                                case .empty: ProgressView().frame(width: 30, height: 30)
                                case .success(let img): img.resizable().aspectRatio(contentMode: .fill).frame(width: 30, height: 30).clipShape(Circle())
                                case .failure: Image(systemName: "photo.circle.fill").resizable().scaledToFit().frame(width: 30, height: 30).foregroundColor(.gray)
                                @unknown default: EmptyView().frame(width: 30, height: 30)
                                }
                            }
                        } else {
                            Image(systemName: "exclamationmark.circle.fill").resizable().scaledToFit().frame(width: 30, height: 30).foregroundColor(.orange)
                        }
                    } else { Image(systemName: "book.fill").resizable().scaledToFit().frame(width: 30, height: 30) }
                    Text(displayTitle).font(.headline).fontWeight(.bold).lineLimit(2).minimumScaleFactor(0.8)
                    Spacer()
                }.padding([.horizontal, .top])

                let pages = groupContentIntoPages(content: course.content ?? [])
                if !pages.isEmpty {
                    TabView(selection: $currentPageIndex) {
                        ForEach(pages.indices, id: \.self) { pageIndex in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 15) {
                                    ForEach(pages[pageIndex], id: \.uniqueIdForList) { item in
                                        if item.__component != "content.pagebreaker" {
                                            ContentComponentView(contentItem: item, language: selectedLanguage)
                                                .id(item.uniqueIdForList)
                                        }
                                    }
                                }.padding()
                            }.tag(pageIndex)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hides default dots
                    .animation(.easeInOut, value: currentPageIndex)
                    
                    // Custom Navigation Controls
                    HStack {
                        let pageBreakerSettings = findPageBreakerSettings(forCurrentPage: currentPageIndex, totalPages: pages.count, allContent: course.content ?? [])
                        
                        if pageBreakerSettings.showBackButton {
                            Button { withAnimation { currentPageIndex -= 1 } } label: { Image(systemName: "arrow.left.circle.fill").font(.title) }
                        } else {
                            Spacer().frame(width: 44) // Keep spacing consistent if button is hidden
                        }
                        Spacer()
                        Text("Page \(currentPageIndex + 1) of \(pages.count)").font(.caption)
                        Spacer()
                        if pageBreakerSettings.showNextButton {
                            Button { withAnimation { currentPageIndex += 1 } } label: { Image(systemName: "arrow.right.circle.fill").font(.title) }
                        } else {
                             Spacer().frame(width: 44) // Keep spacing consistent
                        }
                    }.padding()
                } else {
                    Text("No content for this course.").foregroundColor(.gray).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if !viewModel.isLoading { // Course is nil, not loading, no error yet means no data
                 Text("Course data not found.").foregroundColor(.gray).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(viewModel.course?.translations?[selectedLanguage]?.title ?? viewModel.course?.title ?? "Course")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                 Button { showLanguagePicker = true } label: { Image(systemName: "globe") }
            }
        }
        .popover(isPresented: $showLanguagePicker) { LanguagePickerView(selectedLanguage: $selectedLanguage) }
        .task { await viewModel.fetchCourse(courseId: courseId) }
    }

    func groupContentIntoPages(content: [Content]) -> [[Content]] {
        var pages: [[Content]] = []
        var currentPage: [Content] = []
        for item in content {
            if item.__component == "content.pagebreaker" {
                if !currentPage.isEmpty { pages.append(currentPage) }
                currentPage = [] // Pagebreaker itself doesn't go onto a page
            } else { currentPage.append(item) }
        }
        if !currentPage.isEmpty { pages.append(currentPage) }
        // If there's content but no pagebreakers, it's all one page
        if pages.isEmpty && !content.isEmpty {
            pages.append(content.filter { $0.__component != "content.pagebreaker" })
        }
        return pages
    }
    
    /// Determines button visibility based on the `pagebreaker` that *ends* the page *before* the current one (for back)
    /// and the pagebreaker that *ends* the *current* page (for next).
    func findPageBreakerSettings(forCurrentPage pageIdx: Int, totalPages: Int, allContent: [Content]) -> (showBackButton: Bool, showNextButton: Bool) {
        var canGoBack = true
        var canGoNext = true

        if pageIdx == 0 {
            canGoBack = false // Cannot go back from the first page
        } else {
            // Find the pagebreaker that *ended the previous page* (i.e., started the current page)
            var pageCounter = 0
            var foundPageBreakerForBack: Content?
            for item in allContent {
                 if item.__component == "content.pagebreaker" {
                    if pageCounter == pageIdx - 1 { // This is the pagebreaker that ended the previous page
                        foundPageBreakerForBack = item
                        break
                    }
                    pageCounter += 1
                }
            }
            canGoBack = foundPageBreakerForBack?.backbutton ?? true
        }

        if pageIdx >= totalPages - 1 {
            canGoNext = false // Cannot go next from the last page
        } else {
            // Find the pagebreaker that *ends the current page*
            var pageCounter = 0
            var foundPageBreakerForNext: Content?
            for item in allContent {
                if item.__component == "content.pagebreaker" {
                     if pageCounter == pageIdx { // This is the pagebreaker that ends the current page
                        foundPageBreakerForNext = item
                        break
                    }
                    pageCounter += 1
                }
            }
            canGoNext = foundPageBreakerForNext?.nextbutton ?? true
        }
        
        return (showBackButton: canGoBack, showNextButton: canGoNext)
    }
}


struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) var dismiss // Used to dismiss the popover

    var body: some View {
        NavigationView { // Often good to embed lists in NavigationView for titles/toolbars in popovers
            List {
                Button("English") { selectedLanguage = "en"; dismiss() }
                Button("Spanish") { selectedLanguage = "es"; dismiss() }
                // Add more languages as needed
            }
            .navigationTitle("Select Language")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { // Or .navigationBarTrailing
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

@MainActor
class ShowACourseViewModel: ObservableObject {
    @Published var course: Course?
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    func fetchCourse(courseId: Int) async {
        isLoading = true; errorMessage = nil
        print("Fetching course with ID: \(courseId)")
        guard let token = keychain["jwt"] else {
            print("Error: No JWT token found in Keychain.")
            errorMessage = "Authentication token not found."; isLoading = false; return
        }

        // --- UPDATED POPULATE QUERY ---
        // Using the highly specific query to ensure all fields are populated correctly.
        let populateQuery = "populate[icon_image][populate]=*&populate[category]=*&populate[content][on][coursecontent.text][populate]=data&populate[content][on][coursecontent.image][populate]=image_file&populate[content][on][coursecontent.video][populate]=video_file&populate[content][on][coursecontent.external-video][populate]=thumbnail&populate=translations"
        
        guard let url = URL(string: "\(strapiUrl)/courses/\(courseId)?\(populateQuery)") else {
            print("Error: Invalid URL for fetching course: \(strapiUrl)/courses/\(courseId)?\(populateQuery)")
            errorMessage = "Internal error: Invalid URL."; isLoading = false; return
        }
        
        var request = URLRequest(url: url); request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        print("Fetching course ID \(courseId) from URL: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response from server for course ID \(courseId).")
                errorMessage = "Invalid server response."; isLoading = false; return
            }
            
            print("Show course (ID: \(courseId)) status: \(httpResponse.statusCode)")
            if let responseBody = String(data: data, encoding: .utf8) {
                print("Response body for course \(courseId): \(String(responseBody))")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                var detailedError = "Server error \(httpResponse.statusCode)."
                print("Error: Received HTTP \(httpResponse.statusCode) for course fetch (ID: \(courseId)).")
                if let errData = try? JSONDecoder().decode(StrapiErrorResponse.self, from: data) {
                    detailedError = errData.error.message
                    print("Strapi error for course \(courseId): \(errData.error.message) - \(errData.error.details ?? .null)")
                } else if let responseBody = String(data: data, encoding: .utf8) {
                    print("Error response body for course \(courseId): \(responseBody)")
                }
                errorMessage = detailedError
                isLoading = false; return
            }
            
            let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
            // Use StrapiSingleResponse for fetching a single course
            let decodedResponse = try decoder.decode(StrapiSingleResponse<Course>.self, from: data)
            self.course = decodedResponse.data
            print("Successfully fetched course: \(self.course?.title ?? "Unknown Title") (ID: \(courseId))")

        } catch {
            if let decError = error as? DecodingError {
                 errorMessage = "Data parsing error. Check if the Swift models match the JSON response."
                 print("Decoding error details for course \(courseId): \(decError)")
            }
            else { errorMessage = "Fetch error: \(error.localizedDescription)" }
             print("Fetch course ID \(courseId) error: \(error)")
        }
        isLoading = false
    }
}
