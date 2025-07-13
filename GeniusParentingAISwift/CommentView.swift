import SwiftUI

struct CommentView: View {
    @StateObject private var viewModel: CommentViewModel
    @Environment(\.dismiss) private var dismiss

    init(postId: Int) {
        _viewModel = StateObject(wrappedValue: CommentViewModel(postId: postId))
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading && viewModel.comments.isEmpty {
                    ProgressView("Loading comments...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                List(viewModel.comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(comment.attributes.author?.data?.attributes.username ?? "Anonymous")
                            .font(.headline)
                        Text(comment.attributes.message)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)

                Spacer()

                // Input area
                HStack {
                    TextField("Add a comment...", text: $viewModel.newCommentText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.leading)

                    Button(action: {
                        Task { await viewModel.submitComment() }
                    }) {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.title)
                    }
                    .padding(.trailing)
                    .disabled(viewModel.newCommentText.isEmpty || viewModel.isLoading)
                }
                .padding(.bottom)
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
