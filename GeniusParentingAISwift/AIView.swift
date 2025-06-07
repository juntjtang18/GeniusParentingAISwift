import SwiftUI

struct AIView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var newMessage: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Chat messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                // --- FIX: Updated .onChange syntax for iOS 17+ ---
                .onChange(of: viewModel.messages) {
                    // The scrolling fix remains the same.
                    if let lastMessage = viewModel.messages.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.spring()) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // Input area
            HStack(spacing: 12) {
                TextField("Ask a parenting question...", text: $newMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .padding(.vertical, 8)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isAwaitingResponse)
            }
            .padding([.horizontal, .bottom])
            .padding(.top, 8)
            .background(.thinMaterial)
        }
        .navigationTitle("AI Assistant")
        .onAppear {
            if viewModel.messages.isEmpty {
                 let greeting = ChatMessage(content: "Hello! How can I help you with your parenting questions today?", isUser: false)
                 viewModel.messages.append(greeting)
            }
        }
    }

    private func sendMessage() {
        viewModel.sendMessage(text: newMessage)
        newMessage = ""
    }
}

// The MessageView subview remains unchanged.
struct MessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isUser {
                // Bot's message with avatar on the left
                Image("chatbot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(UIColor.systemGray4), lineWidth: 1))

                Text(message.content)
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(Color(UIColor.label))
                    .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])

                Spacer(minLength: 50)
            } else {
                // User's message with avatar on the right
                Spacer(minLength: 50)

                Text(message.content)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])

                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(UIColor.systemGray3))
            }
        }
        .padding(.horizontal)
    }
}

// The RoundedCorner extension remains unchanged.
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
