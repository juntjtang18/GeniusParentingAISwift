import SwiftUI

struct AIView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var newMessage: String = ""
    @State private var isInputExpanded: Bool = false
    @State private var lines: Int = 1
    @Environment(\.theme) var theme: Theme
    
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id("bottomAnchor")
                    }
                    .padding()
                }
                .onTapGesture {
                    isTextFieldFocused = false
                }
                .onReceive(viewModel.$messages) { _ in
                    DispatchQueue.main.async {
                        withAnimation(.spring()) {
                            proxy.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                }
            }

            Spacer()

            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 4)

                HStack(alignment: .bottom, spacing: 8) {
                    ZStack(alignment: .topTrailing) {
                        ZStack(alignment: .topLeading) {
                            if newMessage.isEmpty {
                                Text("Ask a parenting question...")
                                    .foregroundColor(theme.text.opacity(0.6))
                                    .padding(.horizontal, 16.5)
                                    .padding(.vertical, 10)
                                    .allowsHitTesting(false)
                            }
                            
                            TextField("", text: $newMessage, axis: .vertical)
                                .foregroundColor(theme.text)
                                .focused($isTextFieldFocused)
                                .submitLabel(.done)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                        }
                        .lineLimit(lines == 1 ? 1 : (lines == 2 ? 3 : 4), reservesSpace: true)
                        .background(theme.background)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(UIColor.systemGray4), lineWidth: 0.5)
                        )

                        if !isInputExpanded {
                            Button(action: {
                                withAnimation {
                                    isInputExpanded = true
                                    lines = 2
                                }
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color(UIColor.systemGray5).opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .offset(x: -5, y: 5)
                        } else {
                            Button(action: {
                                withAnimation {
                                    if lines == 2 {
                                        lines = 3
                                    } else {
                                        isInputExpanded = false
                                        lines = 1
                                    }
                                }
                            }) {
                                Image(systemName: lines == 2 ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color(UIColor.systemGray5).opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .offset(x: -5, y: 5)
                        }
                    }

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : theme.accent)
                    }
                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isAwaitingResponse)

                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundColor(theme.accent)
                    }

                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .onAppear {
            if viewModel.messages.isEmpty {
                let greeting = ChatMessage(content: "Hello! How can I help you with your parenting questions today?", isUser: false)
                viewModel.messages.append(greeting)
            }
        }
    }

    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        viewModel.sendMessage(text: trimmedMessage)
        newMessage = ""
        withAnimation {
            isInputExpanded = false
            lines = 1
        }
        isTextFieldFocused = false
    }
}

// The MessageView and RoundedCorner extensions remain unchanged.
struct MessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isUser {
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
