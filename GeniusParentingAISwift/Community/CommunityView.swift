// CommunityView.swift

import SwiftUI
import Foundation

struct CommunityView: View {
    @Environment(\.theme) var currentTheme: Theme
    @StateObject private var viewModel = CommunityViewModel()
    @State private var isShowingAddPostView = false
    @State private var toastMessage: String?
    @ObservedObject private var refresh = RefreshCoordinator.shared
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [currentTheme.background, currentTheme.background2],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Main Content: List of posts
            List {
                ForEach(viewModel.postRowViewModels) { rowViewModel in
                    PostCardView(viewModel: rowViewModel, onToast: { msg in
                        toastMessage = msg
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { toastMessage = nil }
                        }
                    })
                    .padding(12)
                    .background(currentTheme.accentBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(currentTheme.border.opacity(0.12), lineWidth: 1)
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .onAppear { viewModel.fetchMorePostsIfNeeded(currentItem: rowViewModel) }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .refreshable {
                await viewModel.initialLoad()
            }
            
            // ✅ MODIFIED: The initial ProgressView is now a floating overlay
            if viewModel.isLoading && viewModel.postRowViewModels.isEmpty {
                ProgressView("Loading Community...")
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 10)
            }

            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { isShowingAddPostView = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.accentColor)
                            .shadow(radius: 5)
                    }
                    .padding()
                }
            }

            // Toast Banner Overlay
            if let msg = toastMessage {
                VStack {
                    Spacer()
                    ToastBanner(text: msg)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: toastMessage)
            }
        }
        .task {
            if viewModel.postRowViewModels.isEmpty {
                await viewModel.initialLoad()
            }
        }
        .onAppear {
            Task {
                if RefreshCoordinator.shared.consumeCommunityNeedsRefresh() {
                    await viewModel.initialLoad()
                }
            }
        }
        .sheet(isPresented: $isShowingAddPostView, onDismiss: {
            Task {
                if RefreshCoordinator.shared.consumeCommunityNeedsRefresh() {
                    await viewModel.initialLoad()
                }
            }
        }) {
            AddPostView(communityViewModel: viewModel)
        }
        .onAppear {
            if #available(iOS 16.0, *) {} else { UITableView.appearance().backgroundColor = .clear }
        }
        .onDisappear {
            if #available(iOS 16.0, *) {} else { UITableView.appearance().backgroundColor = .systemBackground }
        }
        .onChange(of: viewModel.errorMessage) { msg in
            guard let msg = msg, !msg.isEmpty else { return }
            toastMessage = msg
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    toastMessage = nil
                    viewModel.errorMessage = nil
                }
            }
        }
        .onChange(of: refresh.needsCommunityRefresh) { needs in
            guard needs else { return }
            Task { await viewModel.initialLoad() }
            _ = refresh.consumeCommunityNeedsRefresh()
        }
        //.onReceive(NotificationCenter.default.publisher(for: .communityPostsShouldRefresh)) { note in
        //    Task { await viewModel.initialLoad() }
        //}
    }
}

// Unchanged
private struct ToastBanner: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 8, x: 0, y: 4)
            .multilineTextAlignment(.center)
    }
}


extension Notification.Name {
    static let communityPostsShouldRefresh = Notification.Name("communityPostsShouldRefresh")
}

enum CommunityRefreshReason: String {
    case commented, editedComment, deletedComment, other
}
