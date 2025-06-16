// AddPostViewModel.swift

import Foundation
import SwiftUI
import PhotosUI

@MainActor
class AddPostViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var selectedPhotoItems: [PhotosPickerItem] = [] {
        didSet {
            Task {
                await loadImages()
            }
        }
    }
    @Published var selectedImages: [UIImage] = []
    
    @Published var isPosting = false
    @Published var errorMessage: ErrorMessage? = nil
    @Published var postSuccessfullyCreated = false

    private var mediaData: [Data] = []
    private var communityViewModel: CommunityViewModel

    init(communityViewModel: CommunityViewModel) {
        self.communityViewModel = communityViewModel
    }

    func createPost() async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = ErrorMessage(message: "Post content cannot be empty.")
            return
        }
        
        isPosting = true
        
        do {
            // Pass content and media data to the community view model to handle the network request
            try await communityViewModel.createPost(content: content, mediaData: mediaData)
            postSuccessfullyCreated = true
        } catch {
            errorMessage = ErrorMessage(message: "Failed to create post: \(error.localizedDescription)")
        }
        
        isPosting = false
    }

    private func loadImages() async {
        var newImages: [UIImage] = []
        var newMediaData: [Data] = []

        for item in selectedPhotoItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    newImages.append(image)
                    newMediaData.append(data)
                }
            }
        }
        selectedImages = newImages
        self.mediaData = newMediaData
    }
}
