// GeniusParentingAISwift/HomeView.swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Binding var selectedLanguage: String
    @Binding var isSideMenuShowing: Bool
    @Environment(\.theme) var theme: Theme
    @Environment(\.appDimensions) var dims

    @State private var selectedTip: Tip? = nil
    @State private var searchText: String = ""
    @State private var showCourseList = false   // ⬅️ NEW
    @EnvironmentObject private var tabRouter: MainTabRouter    // ⬅️ add

    private var cardWidth: CGFloat { dims.screenSize.width * 0.85 }
    private var cardHeight: CGFloat { cardWidth * 0.9 }
    private let shadowAllowance: CGFloat = 12

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Welcome Row
                WelcomeRow(
                    profileName: profileName,
                    onAvatarTap: { withAnimation(.easeInOut) { isSideMenuShowing.toggle() } }
                )
                .padding(.top, 6)

                // MARK: Search
                SearchBar(
                    text: $searchText,
                    placeholder: "Search Courses",
                    onSubmit: {
                        // Optional: push to CourseView and leverage search later
                    }
                )

                // MARK: Your Courses + See All
                SectionHeader(
                    title: "Your Courses",
                    trailing: "See All",
                    onTapTrailing: { tabRouter.selectedTab = 1 }   // ⬅️ switch to Course tab
                )

                // Horizontal carousel of today's courses (reusing your model + card)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 15) {
                        if viewModel.isLoading {
                            ProgressView().frame(width: cardWidth, height: cardHeight)
                        } else if viewModel.todaysLessons.isEmpty {
                            Text("No lessons for today.")
                                .frame(width: cardWidth, height: cardHeight)
                                .multilineTextAlignment(.center)
                        } else {
                            ForEach(viewModel.todaysLessons) { lesson in
                                NavigationLink(
                                    destination: ShowACourseView(
                                        selectedLanguage: $selectedLanguage,
                                        courseId: lesson.id,
                                        isSideMenuShowing: $isSideMenuShowing
                                    )
                                ) {
                                    LessonCardView(
                                        lesson: lesson,
                                        cardWidth: self.cardWidth,
                                        cardHeight: self.cardHeight
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, shadowAllowance / 2)
                    .frame(height: cardHeight + shadowAllowance)
                }

                // MARK: Features
                Text("Features")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)

                FeatureGrid {
                    // Hot Topics tile
                    NavigationLink {
                        HotTopicsListScreen(
                            topics: viewModel.hotTopics,
                            isLoading: viewModel.isLoadingHotTopics
                        )
                    } label: {
                        FeatureCard(
                            systemImage: "flame.fill",
                            title: "Hot Topics",
                            tint: theme.primary
                        )
                    }

                    // Tips tile
                    NavigationLink {
                        DailyTipsListScreen(
                            tips: viewModel.dailyTips,
                            isLoading: viewModel.isLoadingDailyTips
                        )
                    } label: {
                        FeatureCard(
                            systemImage: "checkmark.seal.fill",
                            title: "Tips",
                            tint: theme.primary
                        )
                    }

                    // Community tile
                    Button {
                        tabRouter.selectedTab = 3   // same as tapping the Community tab
                    } label: {
                        FeatureCard(
                            systemImage: "person.3.fill",
                            title: "Community",
                            tint: theme.primary
                        )
                    }
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(theme.background)
        .background(
                    NavigationLink(
                        destination: CourseView(
                            selectedLanguage: $selectedLanguage,
                            isSideMenuShowing: $isSideMenuShowing
                        ),
                        isActive: $showCourseList
                    ) { EmptyView() }
                    .hidden()
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
                await viewModel.fetchDailyLessons()   // uses HomeViewModel’s API
                await viewModel.fetchHotTopics()
                await viewModel.fetchDailyTips()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var profileName: String {
        SessionManager.shared.currentUser?.username ?? "there"
    }
}

// Welcome row with avatar and "Welcome back"
// MARK: Welcome row with avatar and "Welcome back"
private struct WelcomeRow: View {
    @Environment(\.theme) var theme: Theme
    let profileName: String
    let onAvatarTap: () -> Void    // NEW

    var body: some View {
        HStack(spacing: 12) {
            // Avatar -> opens side menu
            Button(action: onAvatarTap) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome back")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.85))
                Text(profileName)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
            }

            Spacer()
        }
    }
}


// Rounded search field
private struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var onSubmit: () -> Void = {}

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

// Section title with optional trailing action ("See All")
private struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var onTapTrailing: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
            Spacer()
            if let trailing, let onTapTrailing {
                Button(trailing, action: onTapTrailing)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

// 3-up feature grid
private struct FeatureGrid<Content: View>: View {
    @ViewBuilder var content: () -> Content
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            content()
        }
    }
}

private struct FeatureCard: View {
    let systemImage: String
    let title: String
    let tint: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .padding(12)
                .background(tint.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
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
struct PlayButtonView: View {
    @Environment(\.theme) var theme: Theme
    
    var body: some View {
        ZStack {
            Circle().fill(theme.primary)
            Image(systemName: "play.fill")
                .foregroundColor(theme.primaryText)
                .font(.system(size: 20))
        }
        .frame(width: 50, height: 50)
    }
}

// A simple Hot Topics list using your existing card + data flow
private struct HotTopicsListScreen: View {
    let topics: [Topic]
    let isLoading: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView().padding(.top, 40)
                } else {
                    ForEach(topics) { t in
                        HotTopicCardView(topic: t)
                            .frame(height: 250)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Hot Topics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// A simple Daily Tips list using your existing card + popup behavior
private struct DailyTipsListScreen: View {
    let tips: [Tip]
    let isLoading: Bool
    @State private var selectedTip: Tip? = nil

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        ProgressView().padding(.top, 40)
                    } else {
                        ForEach(tips) { tip in
                            DailyTipCardView(tip: tip)
                                .frame(height: 250)
                                .padding(.horizontal, 16)
                                .onTapGesture { withAnimation(.spring()) { selectedTip = tip } }
                        }
                    }
                }
                .padding(.vertical, 16)
            }

            if let tip = selectedTip {
                FairyTipPopupView(
                    tip: tip,
                    isPresented: Binding(
                        get: { selectedTip != nil },
                        set: { if !$0 { withAnimation(.spring()) { selectedTip = nil } } }
                    )
                )
            }
        }
        .navigationTitle("Daily Tips")
        .navigationBarTitleDisplayMode(.inline)
    }
}
