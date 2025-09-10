// GeniusParentingAISwift/PostCardView.swift
import SwiftUI

struct PostCardView: View {
    @Environment(\.theme) var currentTheme: Theme
    @ObservedObject var viewModel: PostRowViewModel
    @State private var isShowingCommentView = false

    // NEW: toast callback to parent (CommunityView passes it down)
    var onToast: (String) -> Void = { _ in }

    // NEW: state for report/block UX
    @State private var showReportSheet = false
    @State private var showBlockConfirm = false
    @State private var working = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Post Content
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading) {
                        // This HStack ensures username and time are on the same line
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(viewModel.post.attributes.users_permissions_user?.data?.attributes.username ?? "Unknown User")
                                .font(.headline)

                            Text(timeAgo(from: viewModel.post.attributes.createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // NEW: Ellipsis menu for Report / Block
                    Menu {
                        Button(role: .destructive) {
                            showReportSheet = true
                        } label: {
                            Label("Report Post", systemImage: "flag")
                        }

                        if let offenderId = viewModel.post.attributes.users_permissions_user?.data?.id {
                            Button(role: .destructive) {
                                showBlockConfirm = true
                            } label: {
                                Label("Block User", systemImage: "person.crop.circle.badge.xmark")
                            }
                        }
                    } label: {
                        if working {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(working)
                }

                if !viewModel.post.attributes.content.isEmpty {
                    Text(viewModel.post.attributes.content).font(.body)
                        .padding(.top, 4)
                }

                if let media = viewModel.post.attributes.media?.data, !media.isEmpty {
                    PostMediaGridView(media: media)
                        .padding(.top, 4)
                }

                HStack(spacing: 20) {
                    // Like Button
                    Button(action: { viewModel.toggleLike() }) {
                        HStack {
                            Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                                .foregroundColor(viewModel.isLiked ? .red : .gray)
                                .scaleEffect(viewModel.isAnimating ? 1.5 : 1.0)
                                .animation(.interpolatingSpring(stiffness: 170, damping: 10), value: viewModel.isAnimating)
                            Text("\(viewModel.likeCount) likes")
                                .font(.footnote)
                        }
                    }
                    .buttonStyle(.plain)

                    // Comment Button
                    Button(action: { isShowingCommentView = true }) {
                        HStack {
                            Image(systemName: "bubble.right")
                                .foregroundColor(.gray)
                            Text("Comment")
                                .font(.footnote)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
            .padding()

            // Comment Preview Card
            if !viewModel.comments.isEmpty {
                Divider().padding(.horizontal)
                CommentPreviewView(viewModel: viewModel, isShowingCommentView: $isShowingCommentView)
                    .padding(12)
            }
        }
        .cornerRadius(10)
        .fullScreenCover(isPresented: $isShowingCommentView) {
            CommentView(post: viewModel.post)
        }
        // NEW: Report sheet
        .sheet(isPresented: $showReportSheet) {
            ReportFormView(
                title: "Report Post",
                subject: "by @\(viewModel.post.attributes.users_permissions_user?.data?.attributes.username ?? "unknown")",
                onCancel: { showReportSheet = false },
                onSubmit: { reason, details in
                    Task { @MainActor in
                        working = true
                        defer { working = false }
                        do {
                            try await viewModel.reportPost(
                                postId: viewModel.post.id,
                                reason: reason,
                                details: details
                            )
                            showReportSheet = false
                            onToast("Thanks — your report was sent.")
                        } catch {
                            if isAlreadyReportedError(error) {
                                showReportSheet = false
                                onToast("You’ve already reported this post.")
                            } else {
                                // Keep sheet open or close on other errors — your choice:
                                // showReportSheet = false
                                onToast(error.localizedDescription)
                            }
                        }
                    }
                }
            )
        }
        // NEW: Block confirmation
        .confirmationDialog("Block this user?",
                            isPresented: $showBlockConfirm,
                            titleVisibility: .visible) {
            if let offenderId = viewModel.post.attributes.users_permissions_user?.data?.id {
                Button("Block User", role: .destructive) {
                    Task { @MainActor in
                        working = true
                        defer { working = false }
                        do {
                            try await viewModel.blockUser(userId: offenderId)
                            onToast("User blocked.")
                        } catch {
                            onToast(error.localizedDescription)
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func isAlreadyReportedError(_ error: Error) -> Bool {
        let msg = (error as NSError).localizedDescription.lowercased()
        return msg.contains("report already exists") || msg.contains("already reported")
    }

    private func timeAgo(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "Just now" }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute, .second], from: date, to: now)

        if let year = components.year, year > 0 {
            return "\(year) year\(year == 1 ? "" : "s") ago"
        }
        if let month = components.month, month > 0 {
            return "\(month) month\(month == 1 ? "" : "s") ago"
        }
        if let week = components.weekOfYear, week > 0 {
            return "\(week) week\(week == 1 ? "" : "s") ago"
        }
        if let day = components.day, day > 0 {
            return "\(day) day\(day == 1 ? "" : "s") ago"
        }
        if let hour = components.hour, hour > 0 {
            return "\(hour) hour\(hour == 1 ? "" : "s") ago"
        }
        if let minute = components.minute, minute > 0 {
            return "\(minute) minute\(minute == 1 ? "" : "s") ago"
        }
        if let second = components.second, second > 5 {
            return "\(second) second\(second == 1 ? "" : "s") ago"
        }
        return "Just now"
    }
}

// A view to display the comment preview section, now with "load more" capability
struct CommentPreviewView: View {
    @ObservedObject var viewModel: PostRowViewModel
    @Binding var isShowingCommentView: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.comments) { comment in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(comment.attributes.author?.data?.attributes.username ?? "Anonymous")
                                .font(.footnote)
                                .fontWeight(.bold)
                            Spacer()
                            Text(timeAgo(from: comment.attributes.createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(comment.attributes.message)
                            .font(.footnote)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // "Load more" button, loading indicator, or "View all" fallback
            if viewModel.isLoadingMoreComments {
                 ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            } else if viewModel.comments.count < viewModel.totalCommentCount {
                Button(action: {
                    Task { await viewModel.loadMoreComments() }
                }) {
                    Label("Load more comments", systemImage: "ellipsis.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 46) // Align with comment text
                }
                .padding(.top, 4)
            } else if viewModel.totalCommentCount > 3 {
                 Button("View all \(viewModel.totalCommentCount) comments") {
                    isShowingCommentView = true
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 46) // Align with comment text
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
