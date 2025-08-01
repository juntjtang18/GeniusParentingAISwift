// GeniusParentingAISwift/HomeView.swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Binding var selectedLanguage: String
    @Binding var isSideMenuShowing: Bool
    
    @State private var selectedTip: Tip? = nil

    var body: some View {
        ScrollView {
            // Level 1: VStack (Main Container)
            VStack(alignment: .leading, spacing: 10) {
                
                // --- Today's Lesson Section ---
                Text("Today's Lesson")
                    .style(.homeSectionTitle)
                    .padding(.bottom, 5)

                // Level 2: ScrollView (Horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    // Level 3: LazyHStack
                    LazyHStack(spacing: 15) {
                        if viewModel.isLoading {
                            ProgressView().frame(width: 300, height: 250)
                        } else if viewModel.todaysLessons.isEmpty {
                            Text("No lessons for today.").frame(width: 300, height: 250).multilineTextAlignment(.center)
                        } else {
                            // Level 4: Card Views
                            ForEach(viewModel.todaysLessons) { lesson in
                                LessonCardView(lesson: lesson)
                                    .background(
                                        NavigationLink(destination: ShowACourseView(selectedLanguage: $selectedLanguage, courseId: lesson.id, isSideMenuShowing: $isSideMenuShowing)) { EmptyView() }
                                        .opacity(0)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 250)
                }
                .padding(.bottom, 20)

                // --- Hot Topics Section ---
                Text("Hot Topics")
                    .style(.homeSectionTitle)
                    .padding(.bottom, 5)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 15) {
                        if viewModel.isLoadingHotTopics {
                            ProgressView().frame(width: 300, height: 250)
                        } else if viewModel.hotTopics.isEmpty {
                            Text("No hot topics available.").frame(width: 300, height: 250).multilineTextAlignment(.center)
                        } else {
                            ForEach(viewModel.hotTopics) { topic in
                                HotTopicCardView(topic: topic)
                                    .background(
                                        NavigationLink(destination: TopicView(selectedLanguage: $selectedLanguage, topicId: topic.id, isSideMenuShowing: $isSideMenuShowing)) { EmptyView() }
                                        .opacity(0)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 250)
                }
                .padding(.bottom, 20)

                // --- Daily Tips Section ---
                Text("Daily Tips")
                    .style(.homeSectionTitle)
                    .padding(.bottom, 5)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 15) {
                        if viewModel.isLoadingDailyTips {
                            ProgressView().frame(width: 300, height: 250)
                        } else if viewModel.dailyTips.isEmpty {
                            Text("No daily tips available.").frame(width: 300, height: 250).multilineTextAlignment(.center)
                        } else {
                            ForEach(viewModel.dailyTips) { tip in
                                DailyTipCardView(tip: tip)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            self.selectedTip = tip
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 250)
                }
            }
            .padding(.vertical)
        }
        .background(
            Image("background1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
        .overlay {
            if let tip = selectedTip {
                FairyTipPopupView(tip: tip, isPresented: Binding(
                    get: { selectedTip != nil },
                    set: { if !$0 { withAnimation(.spring()) { selectedTip = nil } } }
                ))
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchDailyLessons()
                await viewModel.fetchHotTopics()
                await viewModel.fetchDailyTips()
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
    }
}

// The FairyTipPopupView does not need any changes.
private struct FairyTipPopupView: View {
    let tip: Tip
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .background(.thinMaterial)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            ZStack(alignment: .top) {
                Image("fairy01")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220)
                    .offset(x: -180, y: -77)

                VStack(spacing: 0) {
                    ZStack {
                        AsyncImage(url: URL(string: tip.iconImageMedia?.attributes.url ?? "")) { phase in
                            switch phase {
                            case .empty: ProgressView()
                            case .success(let image): image.resizable().scaledToFill()
                            case .failure: Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray)
                            @unknown default: EmptyView()
                            }
                        }
                    }
                    .frame(height: 200)
                    .clipped()

                    ScrollView {
                        Text(tip.text)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    
                    Spacer()

                    Button("Got it!") { isPresented = false }
                        .font(.headline)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.7, green: 0.9, blue: 0.3))
                        .foregroundColor(.black.opacity(0.7))
                }
                .frame(width: 300, height: 420)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(red: 0.4, green: 0.6, blue: 0.4), lineWidth: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(.horizontal, 40)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
