// AddPostView.swift

import SwiftUI
import PhotosUI

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

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.selectedImages, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }

                    PhotosPicker(
                        selection: $viewModel.selectedPhotoItems,
                        maxSelectionCount: 5, // Allow up to 5 media items
                        matching: .any(of: [.images, .videos])
                    ) {
                        Label("Select Photos/Videos", systemImage: "photo.on.rectangle")
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
