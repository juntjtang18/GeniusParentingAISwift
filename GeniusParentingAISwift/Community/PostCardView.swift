// GeniusParentingAISwift/PostCardView.swift
import SwiftUI

struct PostCardView: View {
    @Environment(\.theme) var currentTheme: Theme
    @ObservedObject var viewModel: PostRowViewModel
    @State private var isShowingCommentView = false

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
