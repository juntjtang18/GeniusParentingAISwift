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
                                // --- FIXED: The parent VStack is now explicitly constrained ---
                                // This creates a stable layout boundary for all child components,
                                // ensuring Text views wrap correctly without expanding off-screen.
                                VStack(alignment: .leading, spacing: 15) {
                                    ForEach(pages[pageIndex], id: \.uniqueIdForList) { item in
                                        if item.__component != "coursecontent.pagebreaker" {
                                            ContentComponentView(contentItem: item, language: selectedLanguage)
                                                .id(item.uniqueIdForList)
                                        }
                                    }
                                }
                                .padding(.horizontal) // Apply horizontal padding to the VStack's content
                                .frame(maxWidth: .infinity, alignment: .leading) // Constrain the VStack to the screen width
                            }.tag(pageIndex)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPageIndex)
                    
                    HStack {
                        let pageBreakerSettings = findPageBreakerSettings(forCurrentPage: currentPageIndex, totalPages: pages.count, allContent: course.content ?? [])
                        
                        if pageBreakerSettings.showBackButton {
                            Button { withAnimation { currentPageIndex -= 1 } } label: { Image(systemName: "arrow.left.circle.fill").font(.title) }
                        } else {
                            Spacer().frame(width: 44)
                        }
                        Spacer()
                        Text("Page \(currentPageIndex + 1) of \(pages.count)").font(.caption)
                        Spacer()
                        if pageBreakerSettings.showNextButton {
                            Button { withAnimation { currentPageIndex += 1 } } label: { Image(systemName: "arrow.right.circle.fill").font(.title) }
                        } else {
                             Spacer().frame(width: 44)
                        }
                    }.padding()
                } else {
                    Text("No content for this course.").foregroundColor(.gray).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if !viewModel.isLoading {
                 Text("Course data not found.").foregroundColor(.gray).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(viewModel.course?.translations?[selectedLanguage]?.title ?? viewModel.course?.title ?? "Course")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task {
                        await viewModel.fetchCourse(courseId: courseId)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                 Button { showLanguagePicker = true } label: { Image(systemName: "globe") }
            }
        }
        .popover(isPresented: $showLanguagePicker) { LanguagePickerView(selectedLanguage: $selectedLanguage) }
        .task {
            if viewModel.course == nil {
                await viewModel.fetchCourse(courseId: courseId)
            }
        }
    }

    func groupContentIntoPages(content: [Content]) -> [[Content]] {
        var pages: [[Content]] = []
        var currentPage: [Content] = []
        for item in content {
            if item.__component == "coursecontent.pagebreaker" {
                if !currentPage.isEmpty { pages.append(currentPage) }
                currentPage = []
            } else { currentPage.append(item) }
        }
        if !currentPage.isEmpty { pages.append(currentPage) }
        if pages.isEmpty && !content.isEmpty {
            pages.append(content.filter { $0.__component != "coursecontent.pagebreaker" })
        }
        return pages
    }
    
    func findPageBreakerSettings(forCurrentPage pageIdx: Int, totalPages: Int, allContent: [Content]) -> (showBackButton: Bool, showNextButton: Bool) {
        var canGoBack = true
        var canGoNext = true
        if pageIdx == 0 {
            canGoBack = false
        } else {
            var pageCounter = 0
            var foundPageBreakerForBack: Content?
            for item in allContent {
                 if item.__component == "coursecontent.pagebreaker" {
                    if pageCounter == pageIdx - 1 {
                        foundPageBreakerForBack = item
                        break
                    }
                    pageCounter += 1
                }
            }
            canGoBack = foundPageBreakerForBack?.backbutton ?? true
        }
        if pageIdx >= totalPages - 1 {
            canGoNext = false
        } else {
            var pageCounter = 0
            var foundPageBreakerForNext: Content?
            for item in allContent {
                if item.__component == "coursecontent.pagebreaker" {
                     if pageCounter == pageIdx {
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
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            List {
                Button("English") { selectedLanguage = "en"; dismiss() }
                Button("Spanish") { selectedLanguage = "es"; dismiss() }
            }
            .navigationTitle("Select Language")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
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
            print("Error: No JWT token found in Keychain."); errorMessage = "Authentication token not found."; isLoading = false; return
        }
        
        // This query now correctly populates all component types and their nested fields
        let populateQuery = "populate[icon_image][populate]=*&populate[category]=*&populate[content][on][coursecontent.text][populate]=*&populate[content][on][coursecontent.image][populate]=*&populate[content][on][coursecontent.video][populate]=*&populate[content][on][coursecontent.quiz][populate]=*&populate[content][on][coursecontent.external-video][populate]=*&populate[content][on][coursecontent.pagebreaker][populate]=*&populate=translations"
        
        guard let url = URL(string: "\(strapiUrl)/courses/\(courseId)?\(populateQuery)") else {
            print("Error: Invalid URL."); errorMessage = "Internal error: Invalid URL."; isLoading = false; return
        }
        
        var request = URLRequest(url: url); request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        print("Fetching course ID \(courseId) from URL: \(url.absoluteString)")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response from server."); errorMessage = "Invalid server response."; isLoading = false; return
            }
            print("Show course (ID: \(courseId)) status: \(httpResponse.statusCode)")
            if let responseBody = String(data: data, encoding: .utf8) { print("Response body for course \(courseId): \(String(responseBody))") }
            guard (200...299).contains(httpResponse.statusCode) else {
                var detailedError = "Server error \(httpResponse.statusCode)."
                if let errData = try? JSONDecoder().decode(StrapiErrorResponse.self, from: data) { detailedError = errData.error.message }
                errorMessage = detailedError; isLoading = false; return
            }
            let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(StrapiSingleResponse<Course>.self, from: data)
            self.course = decodedResponse.data
            print("Successfully fetched course: \(self.course?.title ?? "Unknown Title") (ID: \(courseId))")
        } catch {
            if let decError = error as? DecodingError { errorMessage = "Data parsing error. Check if the Swift models match the JSON response."; print("Decoding error details for course \(courseId): \(decError)") }
            else { errorMessage = "Fetch error: \(error.localizedDescription)" }
            print("Fetch course ID \(courseId) error: \(error)")
        }
        isLoading = false
    }
}
