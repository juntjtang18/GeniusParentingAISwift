// GeniusParentingAISwift/CommentViewModel.swift
import Foundation

@MainActor
class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var newCommentText: String = ""
    @Published var isLoading: Bool = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String? = nil

    private var currentPage = 1
    private var totalPages = 1
    
    let post: Post

    init(post: Post) {
        self.post = post
        Task {
            await fetchComments(isInitialLoad: true)
        }
    }

    func fetchComments(isInitialLoad: Bool) async {
        if isInitialLoad {
            isLoading = true
            currentPage = 1
            totalPages = 1
        } else {
            guard currentPage < totalPages else { return }
            currentPage += 1
            isLoadingMore = true
        }
        errorMessage = nil

        do {
            let response = try await StrapiService.shared.fetchCommentsForPost(postId: post.id, page: currentPage, pageSize: 25)
            
            if let newComments = response.data {
                if isInitialLoad {
                    self.comments = newComments
                } else {
                    self.comments.append(contentsOf: newComments)
                }
            }
            
            if let pagination = response.meta?.pagination {
                self.totalPages = pagination.pageCount
            }
        } catch {
            errorMessage = "Failed to fetch comments: \(error.localizedDescription)"
        }
        
        if isInitialLoad {
            isLoading = false
        } else {
            isLoadingMore = false
        }
    }
    
    func fetchMoreComments() async {
        await fetchComments(isInitialLoad: false)
    }

    func submitComment() async {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Comment cannot be empty."
            return
        }

        // We still need to check for a logged-in user to allow submission
        guard SessionManager.shared.currentUser != nil else {
            errorMessage = "You must be logged in to comment."
            return
        }

        isLoading = true
        errorMessage = nil

        let payloadData = CommentPostData(message: newCommentText, post: post.id)
        let payload = CommentPostPayload(data: payloadData)

        do {
            _ = try await StrapiService.shared.postComment(payload: payload)
            newCommentText = ""
            // Refresh the comments list to show the new one
            await fetchComments(isInitialLoad: true)
        } catch {
            errorMessage = "Failed to post comment: \(error.localizedDescription)"
        }
        isLoading = false
    }
    // MARK: - Moderation wiring
    func reportComment(commentId: Int, reason: ModerationReason = .other, details: String? = nil) async throws {
        errorMessage = nil
        _ = try await ModerationService.shared.reportComment(commentId: commentId, reason: reason, details: details)
        errorMessage = "Comment reported."
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if self.errorMessage == "Comment reported." { self.errorMessage = nil }
        }
    }

    func blockUser(userId: Int) async throws {
        errorMessage = nil
        _ = try await ModerationService.shared.blockUser(userId: userId)
        self.comments.removeAll { $0.attributes.author?.data?.id == userId }
        errorMessage = "User blocked."
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if self.errorMessage == "User blocked." { self.errorMessage = nil }
        }
    }

}
