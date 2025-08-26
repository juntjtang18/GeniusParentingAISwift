// GeniusParentingAISwift/CommunityView.swift
import SwiftUI

struct CommunityView: View {
    @Environment(\.theme) var currentTheme: Theme
    @StateObject private var viewModel = CommunityViewModel()
    @State private var isShowingAddPostView = false

    var body: some View {
        ZStack {
            // ✅ Outermost background from theme, fills safe areas too
            currentTheme.background.ignoresSafeArea()

            VStack {
                if viewModel.isLoading && viewModel.postRowViewModels.isEmpty {
                    ProgressView("Loading Community...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.postRowViewModels) { rowViewModel in
                            PostCardView(viewModel: rowViewModel)
                                // --- Card chrome (gives the view its own background) ---
                                .padding(12)
                                .background(currentTheme.accentBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(currentTheme.border.opacity(0.12), lineWidth: 1)
                                )
                                // --- List cosmetics ---
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear) // keep the row transparent so the screen bg shows around the card
                                .onAppear {
                                    viewModel.fetchMorePostsIfNeeded(currentItem: rowViewModel)
                                }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)        // so your outer theme bg is visible
                    .background(Color.clear)
                }
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
        }
        .task {
            if viewModel.postRowViewModels.isEmpty {
                await viewModel.initialLoad()
            }
        }
        .sheet(isPresented: $isShowingAddPostView, onDismiss: {
            Task { await viewModel.initialLoad() }
        }) {
            AddPostView(communityViewModel: viewModel)
        }
        // ✅ iOS 15 fallback: make UITableView background transparent
        .onAppear {
            if #available(iOS 16.0, *) {
                // no-op; .scrollContentBackground(.hidden) handles it
            } else {
                UITableView.appearance().backgroundColor = .clear
            }
        }
        .onDisappear {
            if #available(iOS 16.0, *) {
                // no-op
            } else {
                UITableView.appearance().backgroundColor = .systemBackground
            }
        }
    }
}
