import Foundation

@MainActor
class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var newCommentText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    let postId: Int

    init(postId: Int) {
        self.postId = postId
        Task {
            await fetchComments()
        }
    }

    func fetchComments() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await StrapiService.shared.fetchCommentsForPost(postId: postId, page: 1, pageSize: 100)
            self.comments = response.data ?? []
        } catch {
            errorMessage = "Failed to fetch comments: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func submitComment() async {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Comment cannot be empty."
            return
        }

        guard let userId = SessionManager.shared.currentUser?.id else {
            errorMessage = "You must be logged in to comment."
            return
        }

        isLoading = true
        errorMessage = nil

        let payloadData = CommentPostData(message: newCommentText, post: postId, author: userId)
        let payload = CommentPostPayload(data: payloadData)

        do {
            _ = try await StrapiService.shared.postComment(payload: payload)
            newCommentText = ""
            // Refresh the comments list to show the new one
            await fetchComments()
        } catch {
            errorMessage = "Failed to post comment: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
