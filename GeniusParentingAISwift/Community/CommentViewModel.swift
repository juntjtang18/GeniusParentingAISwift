// GeniusParentingAISwift/CommentViewModel.swift
import Foundation

@MainActor
class CommentViewModel: ObservableObject {
    private let logger = AppLogger(category: "CommentViewModel")

    @Published var comments: [Comment] = []
    @Published var newCommentText: String = ""
    @Published var isLoading: Bool = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String? = nil
    //@Published var didMutateComments = false

    private var currentPage = 1
    private var totalPages = 1
    
    let post: Post

    init(post: Post) {
        self.post = post
        logger.info("[init] Post id=\(post.id), title='\(post.attributes.content.prefix(50))...'")
        Task {
            await fetchComments(isInitialLoad: true)
        }
    }

    func fetchComments(isInitialLoad: Bool) async {
        if isInitialLoad {
            isLoading = true
            currentPage = 1
            totalPages = 1
            logger.info("[fetchComments] initial load start: postId=\(self.post.id), page=\(self.currentPage)")
        } else {
            guard currentPage < totalPages else { return }
            currentPage += 1
            isLoadingMore = true
            logger.info("[fetchComments] pagination load: postId=\(self.post.id), page=\(self.currentPage)")
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
                // Detailed success logs
                let total = self.comments.count
                let pageCount = response.meta?.pagination?.pageCount ?? 0
                let pageSize = response.meta?.pagination?.pageSize ?? 0
                logger.info("[fetchComments] success: received=\(newComments.count), totalNow=\(total), page=\(self.currentPage)/\(pageCount), pageSize=\(pageSize)")
                // Log first few comment identities to verify payload
                for c in self.comments.prefix(5) {
                    let uid = c.attributes.author?.data?.id ?? -1
                    let uname = c.attributes.author?.data?.attributes.username ?? "unknown"
                    logger.debug("[fetchComments] comment id=\(c.id), by #\(uid) @\(uname), createdAt=\(c.attributes.createdAt)")
                }
            }
            
            if let pagination = response.meta?.pagination {
                self.totalPages = pagination.pageCount
                logger.debug("[fetchComments] pagination meta: page=\(pagination.page), pageCount=\(pagination.pageCount), total=\(pagination.total)")

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
            //self.didMutateComments = true
            RefreshCoordinator.shared.markCommunityNeedsRefresh()   // <- key line

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
        logger.info("[blockUser] blocking userId=\(userId)")
        _ = try await ModerationService.shared.blockUser(userId: userId)
        self.comments.removeAll { $0.attributes.author?.data?.id == userId }
        errorMessage = "User blocked."
        logger.info("[blockUser] success; pruned comments by userId=\(userId). Remaining=\(self.comments.count)")

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if self.errorMessage == "User blocked." { self.errorMessage = nil }
        }
    }

}
