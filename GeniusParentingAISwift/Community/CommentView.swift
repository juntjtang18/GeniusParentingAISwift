// GeniusParentingAISwift/CommentView.swift
import SwiftUI

struct CommentView: View {
    @StateObject private var viewModel: CommentViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme: Theme

    init(post: Post) {
        _viewModel = StateObject(wrappedValue: CommentViewModel(post: post))
    }

    var body: some View {
        NavigationView {
            // The entire view is now a single scrollable container
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PostContentView(post: viewModel.post)
                        .padding()
                    
                    Divider()

                    // The input area is now at the top of the comments section
                    CommentInputArea(viewModel: viewModel)
                    
                    CommentsListView(viewModel: viewModel)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel Button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Sub-views for CommentView
private struct CommentsListView: View {
    @ObservedObject var viewModel: CommentViewModel

    var body: some View {
        if viewModel.isLoading && viewModel.comments.isEmpty {
            ProgressView("Loading comments...")
                .padding()
                .frame(maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .padding()
                .frame(maxHeight: .infinity)
        } else if viewModel.comments.isEmpty {
            Text("No comments yet.")
                .foregroundColor(.secondary)
                .padding()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Comments are now reversed for descending order
                ForEach(viewModel.comments.reversed()) { comment in
                    CommentRowView(comment: comment)
                }
            }
            .padding(.top)
        }
    }
}

private struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(comment.attributes.author?.data?.attributes.username ?? "Anonymous")
                        .font(.footnote)
                        .fontWeight(.semibold)
                    Text(timeAgo(from: comment.attributes.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.attributes.message)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()

            Button(action: {}) {
                Image(systemName: "ellipsis")
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func timeAgo(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "Just now" }
        
        let now = Date()
        let formatter_display = RelativeDateTimeFormatter()
        formatter_display.unitsStyle = .full
        return formatter_display.localizedString(for: date, relativeTo: now)
    }
}

private struct CommentInputArea: View {
    @ObservedObject var viewModel: CommentViewModel
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // "Commenting as" section
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                VStack(alignment: .leading) {
                    Text(SessionManager.shared.currentUser?.username ?? "Current User")
                        .fontWeight(.medium)
                        .font(.footnote)
                    Text("@\(SessionManager.shared.currentUser?.username.lowercased() ?? "userhandle")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                /*
                Spacer()
                Button(action: {}) {
                    Image(systemName: "pencil")
                }
                .foregroundColor(.secondary)
                 */
            }

            // Input field
            VStack(spacing: 4) {
                ZStack(alignment: .topLeading) {
                    if viewModel.newCommentText.isEmpty {
                        Text("Add a comment...")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.7))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $viewModel.newCommentText)
                        .font(.footnote)
                        .focused($isTextFieldFocused)
                        .frame(maxHeight: 150) // Allow growing up to a limit
                        .opacity(viewModel.newCommentText.isEmpty ? 0.25 : 1)
                }
                
                Divider()
                    .background(isTextFieldFocused ? .blue : .gray)
            }
            .padding(.leading, 52) // Indent to align with text above

            // Action buttons appear when typing
            if isTextFieldFocused || !viewModel.newCommentText.isEmpty {
                HStack {
                    Spacer()
                    Button("Cancel") {
                        viewModel.newCommentText = ""
                        isTextFieldFocused = false
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    
                    Button("Comment") {
                        Task { await viewModel.submitComment() }
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.newCommentText.isEmpty)
                }
                .padding(.leading, 52)
            }
        }
        .padding()
    }
}


// A simplified view to show the post content at the top
struct PostContentView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle).foregroundColor(.gray)
                VStack(alignment: .leading) {
                    Text(post.attributes.users_permissions_user?.data?.attributes.username ?? "Unknown User")
                        .font(.headline)
                    Text(timeAgo(from: post.attributes.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            if !post.attributes.content.isEmpty {
                Text(post.attributes.content).font(.body)
            }
            
            if let media = post.attributes.media?.data, !media.isEmpty {
                PostMediaGridView(media: media)
                    .padding(.top, 4)
            }
        }
    }
    
    private func timeAgo(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "Just now" }
        
        let now = Date()
        let formatter_display = RelativeDateTimeFormatter()
        formatter_display.unitsStyle = .full
        return formatter_display.localizedString(for: date, relativeTo: now)
    }
}
