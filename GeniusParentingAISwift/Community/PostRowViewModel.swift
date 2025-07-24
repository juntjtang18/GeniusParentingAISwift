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
    
    // State for inline comment loading
    @Published var comments: [Comment]
    @Published var isLoadingMoreComments = false
    private var commentCurrentPage: Int = 1
    private var commentTotalPages: Int
    let totalCommentCount: Int

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
        
        // Initialize comment-related properties from the new structure
        self.comments = post.attributes.comments?.data ?? []
        let pagination = post.attributes.comments?.meta?.pagination
        self.commentTotalPages = pagination?.pageCount ?? 1
        self.totalCommentCount = pagination?.total ?? (post.attributes.comments?.data?.count ?? 0)
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
    
    func loadMoreComments() async {
        guard !isLoadingMoreComments, commentCurrentPage < commentTotalPages else { return }

        isLoadingMoreComments = true
        commentCurrentPage += 1
        
        do {
            // The number of comments to fetch per page (matches the initial preview count)
            let commentsPerPage = 3
            let response = try await StrapiService.shared.fetchCommentsForPost(postId: self.id, page: commentCurrentPage, pageSize: commentsPerPage)
            
            if let newComments = response.data {
                self.comments.append(contentsOf: newComments)
            }
            // Update total pages in case it has changed
            self.commentTotalPages = response.meta?.pagination?.pageCount ?? self.commentTotalPages
            
        } catch {
            print("Error loading more comments for post \(self.id): \(error.localizedDescription)")
            // Revert page number on failure so user can retry
            commentCurrentPage -= 1
        }
        
        isLoadingMoreComments = false
    }
}
