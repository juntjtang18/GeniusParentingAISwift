// PostRowViewModel.swift

import Foundation

@MainActor
class PostRowViewModel: ObservableObject, Identifiable {
    // The underlying, immutable post data
    let post: Post
    
    // The state for our view, which can now change freely
    @Published var isLiked: Bool
    @Published var likeCount: Int
    @Published var isAnimating: Bool = false
    
    // A reference back to the main view model for network operations
    private weak var communityViewModel: CommunityViewModel?
    
    // By making `id` a non-isolated `let` constant, we resolve the warning.
    // The `id` is initialized once and doesn't change, so it's safe to access from any context.
    nonisolated let id: Int

    init(post: Post, isLiked: Bool, communityViewModel: CommunityViewModel) {
        self.post = post
        self.isLiked = isLiked
        self.likeCount = post.attributes.likeCount
        self.communityViewModel = communityViewModel
        self.id = post.id // Initialize the id
    }
    
    func toggleLike() {
        // 1. Update local state immediately for instant UI feedback
        isLiked.toggle()
        isAnimating = true
        
        if isLiked {
            likeCount += 1
        } else {
            likeCount -= 1
        }
        
        // After a short delay, turn off the animation trigger
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.isAnimating = false
        }

        // 2. Ask the main view model to sync the change with the server
        Task {
            await communityViewModel?.toggleLikeOnServer(postId: post.id)
        }
    }
}
