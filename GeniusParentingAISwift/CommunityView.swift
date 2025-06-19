import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var isShowingAddPostView = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if viewModel.isLoading {
                        ProgressView("Loading Community...")
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage).foregroundColor(.red).padding()
                    } else {
                        List(viewModel.postRowViewModels) { rowViewModel in
                            PostView(viewModel: rowViewModel)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 8)
                        }
                        .listStyle(PlainListStyle())
                        .refreshable { await viewModel.initialLoad() }
                    }
                }
                .navigationTitle("Community")
                .navigationBarTitleDisplayMode(.inline)
                
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
            .onAppear {
                if viewModel.postRowViewModels.isEmpty {
                    Task { await viewModel.initialLoad() }
                }
            }
            .sheet(isPresented: $isShowingAddPostView, onDismiss: {
                // Refresh community view when sheet is dismissed
                Task {
                    await viewModel.initialLoad()
                }
            }) {
                // Pass the CommunityViewModel to the AddPostView
                AddPostView(communityViewModel: viewModel)
            }
        }
        .navigationViewStyle(.stack) // FIX: Ensures correct layout on iPad
    }
}

struct PostView: View {
    @ObservedObject var viewModel: PostRowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author section
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle).foregroundColor(.gray)
                Text(viewModel.post.attributes.users_permissions_user?.data?.attributes.username ?? "Unknown User")
                    .font(.headline)
                Spacer()
            }
            
            // Content text
            if !viewModel.post.attributes.content.isEmpty {
                Text(viewModel.post.attributes.content).font(.body)
            }

            // --- NEW: Media Grid Section ---
            // The grid is only shown if the post has media attached.
            if let media = viewModel.post.attributes.media?.data, !media.isEmpty {
                PostMediaGridView(media: media)
                    .padding(.top, 4)
            }
            // --------------------------------

            // Like button and count section
            HStack {
                Button(action: { viewModel.toggleLike() }) {
                    Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isLiked ? .red : .gray)
                        .scaleEffect(viewModel.isAnimating ? 1.5 : 1.0)
                        .animation(.interpolatingSpring(stiffness: 170, damping: 10), value: viewModel.isAnimating)
                }
                .buttonStyle(.plain)
                
                Text("\(viewModel.likeCount) likes")
                    .font(.footnote)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
