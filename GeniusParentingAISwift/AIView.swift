import SwiftUI
import Speech

struct AIView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var newMessage: String = ""
    @State private var isInputExpanded: Bool = false
    @State private var lines: Int = 1
    @State private var isRecording = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

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
                .onChange(of: viewModel.messages) {
                    if let lastMessage = viewModel.messages.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.spring()) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            Spacer()

            // --- INPUT PANEL: Updated Styling ---
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 4)

                HStack(alignment: .bottom, spacing: 8) {
                    ZStack(alignment: .topTrailing) {
                        TextField("Ask a parenting question...", text: $newMessage, axis: .vertical)
                            .lineLimit(lines == 1 ? 1 : (lines == 2 ? 3 : 4), reservesSpace: true)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(UIColor.systemGray4), lineWidth: 0.5)
                            )
                            .submitLabel(.done)

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
                            .foregroundColor(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isAwaitingResponse)

                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }

                    Button(action: toggleRecording) {
                        Image(systemName: isRecording ? "mic.slash.fill" : "mic.fill")
                            .font(.title2)
                            .foregroundColor(isRecording ? .red : .blue)
                    }
                    .disabled(speechRecognizer == nil)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .background(Color(UIColor.systemBackground))
        }
        // Modifiers for title are removed, now handled by MainView
        .onAppear {
            if viewModel.messages.isEmpty {
                let greeting = ChatMessage(content: "Hello! How can I help you with your parenting questions today?", isUser: false)
                viewModel.messages.append(greeting)
            }
            requestSpeechAuthorization()
        }
    }

    private func sendMessage() {
        viewModel.sendMessage(text: newMessage)
        newMessage = ""
        withAnimation {
            isInputExpanded = false
            lines = 1
        }
    }

    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    speechRecognizer?.delegate = nil
                }
            }
        }
    }

    private func toggleRecording() {
        if isRecording {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            isRecording = false
            recognitionTask?.cancel()
            recognitionTask = nil
            recognitionRequest = nil
        } else {
            startRecording()
            isRecording = true
        }
    }

    private func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start failed: \(error)")
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                newMessage = result.bestTranscription.formattedString
            }

            if error != nil || result?.isFinal == true {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                recognitionRequest.endAudio()
                isRecording = false
                recognitionTask = nil
            }
        }
    }
}

// The MessageView subview corrected.
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
