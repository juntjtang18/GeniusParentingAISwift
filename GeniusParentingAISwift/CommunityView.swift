// CommunityView.swift

import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()

    var body: some View {
        NavigationView {
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
            .onAppear {
                if viewModel.postRowViewModels.isEmpty {
                    Task { await viewModel.initialLoad() }
                }
            }
        }
    }
}

struct PostView: View {
    @ObservedObject var viewModel: PostRowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author and content section
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle).foregroundColor(.gray)
                Text(viewModel.post.attributes.users_permissions_user?.data?.attributes.username ?? "Unknown User")
                    .font(.headline)
                Spacer()
            }
            Text(viewModel.post.attributes.content).font(.body)

            // Like button and count section
            HStack {
                Button(action: { viewModel.toggleLike() }) {
                    Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isLiked ? .red : .gray)
                        .scaleEffect(viewModel.isAnimating ? 1.5 : 1.0)
                        .animation(.interpolatingSpring(stiffness: 170, damping: 10), value: viewModel.isAnimating)
                }
                // THIS IS THE FIX:
                // Applying .plain style prevents the List from hijacking the button's
                // behavior and redrawing the whole row.
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
