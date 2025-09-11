// AddPostView.swift

import SwiftUI
import PhotosUI
enum MediaLimits {
    static let maxImagesPerPost = 9
}

struct AddPostView: View {
    @StateObject private var viewModel: AddPostViewModel
    @ObservedObject var communityViewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var currentTheme: Theme
    init(communityViewModel: CommunityViewModel) {
        _viewModel = StateObject(wrappedValue: AddPostViewModel(communityViewModel: communityViewModel))
        self.communityViewModel = communityViewModel
    }

    var body: some View {
        NavigationView {
            ZStack {
                /*
                LinearGradient(
                    colors: [currentTheme.background, currentTheme.background2],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea() // Ensure the gradient fills the entire screen
                 */
                VStack {
                    TextEditor(text: $viewModel.content)
                        .padding()
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding()

                    let gridSpacing: CGFloat = 8
                    let colCount = min(3, max(1, viewModel.selectedImages.count))

                    if !viewModel.selectedImages.isEmpty {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: colCount),
                            spacing: gridSpacing
                        ) {
                            ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { idx, image in
                                SquarePreview(image: image)
                            }
                        }
                        .padding(.horizontal)
                    }

                    PhotosPicker(
                        selection: $viewModel.selectedPhotoItems,
                        maxSelectionCount: MediaLimits.maxImagesPerPost,   // from 5 -> 9
                        matching: .any(of: [.images, .videos])
                    ) {
                        Label("Select Photos", systemImage: "photo.on.rectangle")
                    }
                    .padding()

                    Spacer()
                }
                .navigationTitle("New Post")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Post") {
                            Task {
                                await viewModel.createPost()
                            }
                        }
                        .disabled(viewModel.isPosting || viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .onChange(of: viewModel.postSuccessfullyCreated) { didCreate in
                    if didCreate {
                        dismiss()
                    }
                }

                if viewModel.isPosting {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    ProgressView("Posting...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
            .alert(item: $viewModel.errorMessage) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }
}

// Error message helper
struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

private struct SquarePreview: View {
    let image: UIImage

    var body: some View {
        // A square container that determines the cell size
        Rectangle()
            .fill(Color.clear)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()     // fill and crop to the square
                    .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
