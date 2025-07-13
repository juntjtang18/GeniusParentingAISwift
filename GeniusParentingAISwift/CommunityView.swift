// GeniusParentingAISwift/CommunityView.swift
import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var isShowingAddPostView = false

    var body: some View {
        // FIXED: Removed the redundant NavigationView wrapper.
        ZStack {
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
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 8)
                                .onAppear {
                                    viewModel.fetchMorePostsIfNeeded(currentItem: rowViewModel)
                                }
                        }
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.initialLoad()
                    }
                }
            }
            // FIXED: Navigation properties are now set in MainView for consistency.
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isShowingAddPostView = true
                    }) {
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
            Task {
                await viewModel.initialLoad()
            }
        }) {
            AddPostView(communityViewModel: viewModel)
        }
    }
}
