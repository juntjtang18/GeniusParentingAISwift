import SwiftUI
import KeychainAccess
import AVKit

class CourseCache {
    static let shared = CourseCache()
    private init() {}

    private(set) var courses: [Int: Course] = [:]

    func get(courseId: Int) -> Course? {
        return courses[courseId]
    }

    func set(course: Course) {
        courses[course.id] = course
    }
}


struct ShowACourseView: View {
    @StateObject private var viewModel = ShowACourseViewModel()
    @Binding var selectedLanguage: String
    let courseId: Int
    @State private var currentPageIndex = 0
    
    // FIXED: Add a binding to control the side menu's visibility.
    @Binding var isSideMenuShowing: Bool

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView("Loading Course...").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                 Text("Error: \(errorMessage)").foregroundColor(.red).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let course = viewModel.course {
                let displayTitle = course.translations?[selectedLanguage]?.title ?? course.title
                HStack {
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
                    Text(displayTitle).font(.headline).lineLimit(2).minimumScaleFactor(0.8)
                    Spacer()
                }
                .padding()

                let pages = groupContentIntoPages(content: course.content ?? [])
                if !pages.isEmpty {
                    TabView(selection: $currentPageIndex) {
                        ForEach(pages.indices, id: \.self) { pageIndex in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 15) {
                                    ForEach(pages[pageIndex], id: \.uniqueIdForList) { item in
                                        if item.__component != "coursecontent.pagebreaker" {
                                            ContentComponentView(contentItem: item, language: selectedLanguage)
                                                .id(item.uniqueIdForList)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // FIXED: Use ToolbarItemGroup to show multiple buttons.
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // The original refresh button.
                Button {
                    Task {
                        await viewModel.fetchCourse(courseId: courseId)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                
                // The menu button to open the side menu.
                Button(action: {
                    withAnimation(.easeInOut) {
                        isSideMenuShowing.toggle()
                    }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                }
            }
        }
        .task {
            await viewModel.fetchCourse(courseId: courseId)
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
        if pageIdx == 0 { canGoBack = false }
        else {
            var pageCounter = 0
            var foundPageBreakerForBack: Content?
            for item in allContent {
                 if item.__component == "coursecontent.pagebreaker" {
                    if pageCounter == pageIdx - 1 { foundPageBreakerForBack = item; break }
                    pageCounter += 1
                }
            }
            canGoBack = foundPageBreakerForBack?.backbutton ?? true
        }
        if pageIdx >= totalPages - 1 { canGoNext = false }
        else {
            var pageCounter = 0
            var foundPageBreakerForNext: Content?
            for item in allContent {
                if item.__component == "coursecontent.pagebreaker" {
                     if pageCounter == pageIdx { foundPageBreakerForNext = item; break }
                    pageCounter += 1
                }
            }
            canGoNext = foundPageBreakerForNext?.nextbutton ?? true
        }
        return (showBackButton: canGoBack, showNextButton: canGoNext)
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
        let isRefreshEnabled = UserDefaults.standard.bool(forKey: "isRefreshModeEnabled")
        
        if !isRefreshEnabled, let cachedCourse = CourseCache.shared.get(courseId: courseId) {
            self.course = cachedCourse
            self.isLoading = false
            return
        }

        isLoading = true; errorMessage = nil
        
        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."; isLoading = false; return
        }
        
        let populateQuery = "populate[icon_image]=*&populate[translations]=*&populate[coursecategory]=*&populate[content][populate]=image_file,video_file,thumbnail"
        
        guard let url = URL(string: "\(strapiUrl)/courses/\(courseId)?\(populateQuery)") else {
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
                if let errData = try? JSONDecoder().decode(StrapiErrorResponse.self, from: data) { detailedError = errData.error.message }
                errorMessage = detailedError; isLoading = false; return
            }
            let decoder = JSONDecoder()
            // REMOVED: decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(StrapiSingleResponse<Course>.self, from: data)
            let fetchedCourse = decodedResponse.data
            
            CourseCache.shared.set(course: fetchedCourse)
            self.course = fetchedCourse
            
        } catch {
            if let decError = error as? DecodingError {
                print("Decoding Error in ShowACourseViewModel: \(decError)")
                errorMessage = "Data parsing error. Check if the Swift models match the JSON response."
            }
            else { errorMessage = "Fetch error: \(error.localizedDescription)" }
        }
        isLoading = false
    }
}
