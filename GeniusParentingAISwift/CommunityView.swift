// CommunityView.swift

import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(viewModel.posts) { post in
                        PostView(post: post)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await viewModel.fetchPosts()
                }
            }
        }
    }
}

struct PostView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author Info
            HStack {
                // Placeholder for avatar
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                
                // FIX: Access the username through the new attributes layer.
                Text(post.attributes.users_permissions_user?.data?.attributes.username ?? "Unknown User")
                    .font(.headline)
                Spacer()
            }

            // Content
            Text(post.attributes.content)
                .font(.body)

            // Media
            if let media = post.attributes.media?.data, !media.isEmpty {
                 ForEach(media) { mediaItem in
                    // A more complete implementation would use AsyncImage here.
                    Text("Media: \(mediaItem.attributes.url)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Likes
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(post.attributes.likeCount) likes")
                    .font(.footnote)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CommunityView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityView()
    }
}
