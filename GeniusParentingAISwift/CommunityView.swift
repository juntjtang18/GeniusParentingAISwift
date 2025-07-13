// GeniusParentingAISwift/CommunityView.swift
import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var isShowingAddPostView = false

    var body: some View {
        // FIXED: Removed the redundant NavigationView wrapper.
        ZStack {
            VStack {
                if viewModel.isLoading && viewModel.postRowViewModels.isEmpty {
                    ProgressView("Loading Community...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.postRowViewModels) { rowViewModel in
                            PostView(viewModel: rowViewModel)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 8)
                                .onAppear {
                                    viewModel.fetchMorePostsIfNeeded(currentItem: rowViewModel)
                                }
                        }
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.initialLoad()
                    }
                }
            }
            // FIXED: Navigation properties are now set in MainView for consistency.
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isShowingAddPostView = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.accentColor)
                            .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }
        .task {
            if viewModel.postRowViewModels.isEmpty {
                await viewModel.initialLoad()
            }
        }
        .sheet(isPresented: $isShowingAddPostView, onDismiss: {
            Task {
                await viewModel.initialLoad()
            }
        }) {
            AddPostView(communityViewModel: viewModel)
        }
    }
}

// PostView struct remains the same
struct PostView: View {
    @ObservedObject var viewModel: PostRowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle).foregroundColor(.gray)
                VStack(alignment: .leading) {
                    // --- FIXED: Use the correct camelCase property name ---
                    Text(viewModel.post.attributes.users_permissions_user?.data?.attributes.username ?? "Unknown User")
                        .font(.headline)
                    Text(timeAgo(from: viewModel.post.attributes.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            if !viewModel.post.attributes.content.isEmpty {
                Text(viewModel.post.attributes.content).font(.body)
            }

            if let media = viewModel.post.attributes.media?.data, !media.isEmpty {
                PostMediaGridView(media: media)
                    .padding(.top, 4)
            }

            HStack {
                Button(action: { viewModel.toggleLike() }) {
                    Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isLiked ? .red : .gray)
                        .scaleEffect(viewModel.isAnimating ? 1.5 : 1.0)
                        .animation(.interpolatingSpring(stiffness: 170, damping: 10), value: viewModel.isAnimating)
                }
                .buttonStyle(.plain)
                
                Text("\(viewModel.likeCount) likes")
                    .font(.footnote)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
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
