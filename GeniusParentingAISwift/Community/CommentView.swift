import SwiftUI

struct CommentView: View {
    @StateObject private var viewModel: CommentViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var currentTheme: Theme
    @State private var toastMessage: String?
    //@State private var shouldRefreshOnDismiss = false

    init(post: Post) {
        _viewModel = StateObject(wrappedValue: CommentViewModel(post: post))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // ✅ Screen background
                LinearGradient(
                    colors: [currentTheme.background, currentTheme.background2],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    // ✅ Single “card” that holds the whole thread
                    VStack(alignment: .leading, spacing: 0) {
                        PostContentView(post: viewModel.post)
                            .padding()

                        Divider()

                        CommentInputArea(viewModel: viewModel)
                            .padding(.horizontal)

                        CommentsListView(viewModel: viewModel)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                    .padding(12)
                    .background(currentTheme.accentBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(currentTheme.border.opacity(0.12), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .scrollContentBackground(.hidden) // keep gradient visible around the card
                .background(Color.clear)
                
                if let msg = toastMessage {
                    VStack {
                        Spacer()
                        ToastBanner(text: msg)
                        Spacer()
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: toastMessage)
                }

            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Community")
                        }
                    }
                }
            }
        }
        .task {
            if viewModel.comments.isEmpty && !viewModel.isLoading {
                await viewModel.fetchComments(isInitialLoad: true)
            }
        }
        .onChange(of: viewModel.errorMessage) { msg in
            guard let msg = msg, !msg.isEmpty else { return }
            toastMessage = humanize(msg) // see helper below (optional)
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s
                withAnimation {
                    toastMessage = nil
                    viewModel.errorMessage = nil
                }
            }
        }
        
        //.onChange(of: viewModel.didMutateComments) { changed in
        //    if changed { shouldRefreshOnDismiss = true }
        //}
        //.onDisappear {
        //    // Only tell CommunityView to reload if something actually changed
        //    if shouldRefreshOnDismiss {
        //        NotificationCenter.default.post(
        //            name: .communityPostsShouldRefresh,
        //            object: nil,
        //            userInfo: ["reason": CommunityRefreshReason.commented.rawValue]
        //        )
        //    }
        //}
    }
    
    private func humanize(_ serverMessage: String) -> String {
        if serverMessage.localizedCaseInsensitiveContains("report already exists") {
            return "You’ve already reported this comment."
        }
        return serverMessage
    }
}

// MARK: - Sub-views for CommentView
private struct CommentsListView: View {
    @ObservedObject var viewModel: CommentViewModel

    var body: some View {
        if viewModel.isLoading && viewModel.comments.isEmpty {
            ProgressView("Loading comments...")
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
        } else if let error = viewModel.errorMessage, !error.isEmpty, viewModel.comments.isEmpty {
            Text(error)
                .foregroundColor(.red)
               .padding(.vertical)
        } else if viewModel.comments.isEmpty {
                Text("No comments yet.")
                .foregroundColor(.secondary)
                .padding(.vertical)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.comments, id: \.id) { comment in
                    CommentRowView(comment: comment, viewModel: viewModel)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.top)
        }
    }
}


private struct CommentRowView: View {
    let comment: Comment
    @ObservedObject var viewModel: CommentViewModel
    @State private var showReportConfirm = false
    @State private var showReportSheet = false
    @State private var showBlockConfirm = false
    @State private var working = false

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

            Menu {
                Button(role: .destructive) { showReportSheet = true } label: {
                    Label("Report Comment", systemImage: "flag")
                }

                if let _ = comment.attributes.author?.data?.id {
                    Button(role: .destructive) { showBlockConfirm = true } label: {
                        Label("Block User", systemImage: "person.crop.circle.badge.xmark")
                    }
                }
            } label: {
                if working { ProgressView().scaleEffect(0.6) } else {
                    Image(systemName: "ellipsis").foregroundColor(.secondary)
                }
            }
            .disabled(working)
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showReportSheet) {
            ReportFormView(
                title: "Report Comment",
                subject: "by @\(comment.attributes.author?.data?.attributes.username ?? "unknown")",
                onCancel: { showReportSheet = false },
                onSubmit: { reason, details in
                    Task { @MainActor in
                        working = true
                        defer { working = false }
                        do {
                            try await viewModel.reportComment(
                                commentId: comment.id,
                                reason: reason,
                                details: details
                            )
                            // success → dismiss + (optional) friendly toast
                            showReportSheet = false
                            viewModel.errorMessage = "Thanks — your report was sent."
                        } catch {
                            if isAlreadyReportedError(error) {
                                // already exists → dismiss + toast
                                showReportSheet = false
                                viewModel.errorMessage = "You’ve already reported this comment."
                            } else {
                                // other errors → keep sheet open OR dismiss (your choice)
                                // If you want to keep it open:
                                viewModel.errorMessage = error.localizedDescription
                                // If you prefer to dismiss even on other errors, uncomment:
                                // showReportSheet = false
                            }
                        }
                    }
                }
            )
        }

        .confirmationDialog("Block this user?",
                            isPresented: $showBlockConfirm,
                            titleVisibility: .visible) {
            if let offenderId = comment.attributes.author?.data?.id {
                Button("Block User", role: .destructive) { block(offenderId: offenderId) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    private func isAlreadyReportedError(_ error: Error) -> Bool {
        // Adjust to your API error type if you have one (statusCode == 409, etc.)
        let msg = (error as NSError).localizedDescription.lowercased()
        return msg.contains("report already exists") || msg.contains("already reported")
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

    private func report() {
        Task { @MainActor in
            working = true; defer { working = false }
            do { try await viewModel.reportComment(commentId: comment.id, reason: .other, details: "Reported from iOS") }
            catch { viewModel.errorMessage = error.localizedDescription }
        }
    }

    private func block(offenderId: Int) {
        Task { @MainActor in
            working = true; defer { working = false }
            do { try await viewModel.blockUser(userId: offenderId) }
            catch { viewModel.errorMessage = error.localizedDescription }
        }
    }
}

private struct CommentInputArea: View {
    @Environment(\.theme) var currentTheme: Theme
    @ObservedObject var viewModel: CommentViewModel
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // “Commenting as”
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
            }

            // Input field
            VStack(spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if viewModel.newCommentText.isEmpty {
                        Text("Add a comment...")
                            .font(.footnote)
                            .foregroundColor(currentTheme.inputBoxForeground.opacity(0.6))
                            .padding(.top, 12)
                            .padding(.leading, 10)
                    }

                    TextEditor(text: $viewModel.newCommentText)
                        .font(.footnote)
                        .foregroundColor(currentTheme.inputBoxForeground) // text color
                        .tint(currentTheme.primary)                       // caret/selection
                        .focused($isTextFieldFocused)
                        .frame(minHeight: 80, maxHeight: 150)
                        .padding(10)
                        .background(currentTheme.inputBoxBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(currentTheme.primary, lineWidth: 1) // primary border
                        )
                }
            }


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
            }
        }
        .padding(.vertical)
    }
}

// PostContentView unchanged (kept here for completeness)
struct PostContentView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
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
                Text(post.attributes.content)
                    .font(.body)
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

private struct ToastBanner: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 8, x: 0, y: 4)
            .multilineTextAlignment(.center)
    }
}

