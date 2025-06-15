import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()

    var body: some View {
        List {
            ForEach(viewModel.posts) { post in
                PostRowView(post: post)
                    .environmentObject(viewModel)
                    // The .onAppear modifier is removed from here to prevent the crash
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // --- NEW PAGINATION TRIGGER ---
            // This section at the end of the list handles loading more items.
            if viewModel.hasMorePages {
                // The sentinel view. When this appears, we fetch the next page.
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 1)
                    .onAppear {
                        Task {
                            await viewModel.fetchPosts()
                        }
                    }
            }
            
            // Display a loading spinner at the very bottom if currently fetching
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .listStyle(.plain)
        .onAppear {
            if viewModel.posts.isEmpty {
                Task {
                    await viewModel.fetchPosts()
                }
            }
        }
    }
}

struct PostRowView: View {
    // This is now a 'let' constant again.
    let post: Post
    @EnvironmentObject var viewModel: CommunityViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ... (Author Header, RichTextView, etc. remain the same)
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: post.author?.avatarUrl ?? "")) { image in image.resizable().aspectRatio(contentMode: .fill) }
                placeholder: { Image(systemName: "person.circle.fill").font(.largeTitle).foregroundColor(.gray.opacity(0.5)) }
                .frame(width: 44, height: 44).clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author?.username ?? "Unknown User").fontWeight(.semibold)
                    if let date = post.creationDate { Text(date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.secondary) }
                }
            }
            RichTextView(html: post.content ?? "")
            HStack {
                Button(action: {
                    if viewModel.likedPosts.keys.contains(post.id) {
                        Task { await viewModel.unlikePost(post: post) }
                    } else {
                        Task { await viewModel.likePost(post: post) }
                    }
                }) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(viewModel.likedPosts.keys.contains(post.id) ? .red : .gray)
                }
                .buttonStyle(.plain)

                Text("\(post.likeCount)")
                Spacer()
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
