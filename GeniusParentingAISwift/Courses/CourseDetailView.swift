// GeniusParentingAISwift/Courses/CourseDetailView.swift
import SwiftUI
import AVKit

struct ShowACourseView: View {
    @Environment(\.theme) var theme: Theme
    @StateObject private var viewModel = ShowACourseViewModel()
    @Binding var selectedLanguage: String
    let courseId: Int
    @State private var currentPageIndex = 0
    
    @Binding var isSideMenuShowing: Bool

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView("Loading Course...").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                 Text("Error: \(errorMessage)")
                    .style(.body)
                    .foregroundColor(.red).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                            // NEW: render videos inline with overlay controls
                                            if let urlString = item.video_file?.data?.attributes.url,
                                               let url = URL(string: urlString) {
                                                VideoBlock(url: url)
                                                    .id(item.uniqueIdForList)
                                            } else {
                                                // Non-video items keep their existing renderer
                                                ContentComponentView(contentItem: item, language: selectedLanguage)
                                                    .id(item.uniqueIdForList)
                                            }
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
                        Text("Page \(currentPageIndex + 1) of \(pages.count)")
                            .style(.caption)
                        Spacer()
                        if pageBreakerSettings.showNextButton {
                            Button { withAnimation { currentPageIndex += 1 } } label: { Image(systemName: "arrow.right.circle.fill").font(.title) }
                        } else {
                             Spacer().frame(width: 44)
                        }
                    }.padding()
                } else {
                    Text("No content for this course.")
                        .style(.body)
                        .foregroundColor(.gray).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if !viewModel.isLoading {
                 Text("Course data not found.")
                    .style(.body)
                    .foregroundColor(.gray).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.fetchCourse(courseId: courseId)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise").foregroundColor(theme.accent)
                }
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        isSideMenuShowing.toggle()
                    }
                }) {
                    Image(systemName: "line.3.horizontal").font(.title3)
                        .foregroundColor(theme.accent)
                }
            }
        }
        .task {
            await viewModel.fetchCourse(courseId: courseId)
        }
    }
    
    func groupContentIntoPages(content: [CourseContentItem]) -> [[CourseContentItem]] {
        var pages: [[CourseContentItem]] = []
        var currentPage: [CourseContentItem] = []
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
    
    func findPageBreakerSettings(forCurrentPage pageIdx: Int, totalPages: Int, allContent: [CourseContentItem]) -> (showBackButton: Bool, showNextButton: Bool) {
        var canGoBack = true
        var canGoNext = true
        if pageIdx == 0 { canGoBack = false }
        else {
            var pageCounter = 0
            var foundPageBreakerForBack: CourseContentItem?
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
            var foundPageBreakerForNext: CourseContentItem?
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

    func fetchCourse(courseId: Int) async {
        let isRefreshEnabled = UserDefaults.standard.bool(forKey: "isRefreshModeEnabled")
        
        if !isRefreshEnabled, let cachedCourse = CourseCache.shared.get(courseId: courseId) {
            self.course = cachedCourse
            self.isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        
        let populateQuery = "populate[icon_image]=*&populate[translations]=*&populate[coursecategory]=*&populate[content][populate]=image_file,video_file,thumbnail"
        
        guard let url = URL(string: "\(strapiUrl)/courses/\(courseId)?\(populateQuery)") else {
            errorMessage = "Internal error: Invalid URL."
            isLoading = false
            return
        }
        
        do {
            let fetchedCourse: Course = try await NetworkManager.shared.fetchSingle(from: url)
            
            CourseCache.shared.set(course: fetchedCourse)
            self.course = fetchedCourse
            
        } catch {
            errorMessage = "Fetch error: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

private struct VideoBlock: View {
    let url: URL

    @State private var player: AVPlayer?
    @State private var endObserver: NSObjectProtocol?

    var body: some View {
        VideoPlayer(player: player)
            // Use the system controls; do NOT add overlays or gestures above this.
            .onAppear { setupPlayer() }
            .onDisappear { teardown() }
            .frame(maxWidth: .infinity)
            .aspectRatio(16/9, contentMode: .fit)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    // MARK: - Setup / Cleanup

    private func setupPlayer() {
        // Reuse if same URL; otherwise create a new player
        if let p = player,
           let asset = p.currentItem?.asset as? AVURLAsset,
           asset.url == url {
            attachEndObserver(to: p)
            return
        }
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        player = p
        attachEndObserver(to: p)
    }

    private func attachEndObserver(to player: AVPlayer) {
        // When playback finishes, seek to start so the native Play button can restart immediately
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
        }
    }

    private func teardown() {
        if let token = endObserver {
            NotificationCenter.default.removeObserver(token)
            endObserver = nil
        }
        player?.pause()
        player = nil
    }
}
