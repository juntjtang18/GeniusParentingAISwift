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
    
    var id: Int { post.id }

    init(post: Post, isLiked: Bool, communityViewModel: CommunityViewModel) {
        self.post = post
        self.isLiked = isLiked
        self.likeCount = post.attributes.likeCount
        self.communityViewModel = communityViewModel
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
