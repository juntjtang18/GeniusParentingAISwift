// TopicView.swift

import SwiftUI

struct TopicView: View {
    @Environment(\.theme) var theme: Theme
    @Environment(\.dismiss) private var dismiss // ✅ Add dismiss action
    @StateObject private var viewModel = TopicViewModel()
    @Binding var selectedLanguage: String
    let topicId: Int
    @State private var currentPageIndex = 0
    @Binding var isSideMenuShowing: Bool

    var body: some View {
        // ✅ Wrap the content in a ZStack
        ZStack {
            // ✅ Add the gradient background
            LinearGradient(
                colors: [theme.background, theme.background2],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // This is your original content VStack
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView("Loading Topic...").frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                     Text("Error: \(errorMessage)").foregroundColor(.red).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let topic = viewModel.topic {
                    HStack {
                        if let iconMedia = topic.iconImageMedia {
                            if let imgUrl = URL(string: iconMedia.attributes.url) {
                                AsyncImage(url: imgUrl) { phase in
                                    switch phase {
                                    case .empty: ProgressView().frame(width: 30, height: 30)
                                    case .success(let img): img.resizable().aspectRatio(contentMode: .fill).frame(width: 30, height: 30).clipShape(Circle())
                                    case .failure: Image(systemName: "photo.circle.fill").resizable().scaledToFit().frame(width: 30, height: 30).foregroundColor(.gray)
                                    @unknown default: EmptyView().frame(width: 30, height: 30)
                                    }
                                }
                            }
                        } else {
                            Image(systemName: "lightbulb.fill").resizable().scaledToFit().frame(width: 30, height: 30)
                        }
                        Text(topic.title).font(.headline).lineLimit(2).minimumScaleFactor(0.8)
                        Spacer()
                    }
                    .padding()

                    let pages = groupContentIntoPages(content: topic.content ?? [])
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
                            let pageBreakerSettings = findPageBreakerSettings(forCurrentPage: currentPageIndex, totalPages: pages.count, allContent: topic.content ?? [])
                            
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
                        Text("No content for this topic.").foregroundColor(.gray).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if !viewModel.isLoading {
                     Text("Topic data not found.").foregroundColor(.gray).padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
        .task {
            await viewModel.fetchTopic(topicId: topicId)
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
