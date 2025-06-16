// LikeComponentView.swift

import SwiftUI

struct LikeComponentView: View {
    // State for this view, managed locally for instant UI feedback
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var isAnimating: Bool = false

    // To communicate back to the server
    @ObservedObject var viewModel: CommunityViewModel
    let postId: Int
    
    // Initialize with the starting values from the post
    init(viewModel: CommunityViewModel, postId: Int, initialIsLiked: Bool, initialLikeCount: Int) {
        self.viewModel = viewModel
        self.postId = postId
        self._isLiked = State(initialValue: initialIsLiked)
        self._likeCount = State(initialValue: initialLikeCount)
    }

    var body: some View {
        HStack {
            Button(action: handleLikeTap) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : .gray)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .animation(.interpolatingSpring(stiffness: 170, damping: 10), value: isAnimating)
            }
            Text("\(likeCount) likes")
                .font(.footnote)
        }
    }
    
    private func handleLikeTap() {
        // 1. Update local state immediately for instant UI feedback
        isLiked.toggle()
        isAnimating = true
        
        if isLiked {
            likeCount += 1
        } else {
            likeCount -= 1
        }
        
        // After a short delay, turn off the animation trigger
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isAnimating = false
        }
        
        // 2. Perform the backend operation asynchronously
        Task {
            await viewModel.toggleLikeOnServer(postId: postId)
        }
    }
}
