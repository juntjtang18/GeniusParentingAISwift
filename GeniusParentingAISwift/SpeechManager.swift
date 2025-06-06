import Foundation
import AVFoundation // For AVSpeechSynthesizer
import SwiftUI   // For @MainActor, ObservableObject

// MARK: - Speech Manager

@MainActor
class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var isPaused = false // To correctly manage resume state

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, language: String) {
        // Stop any current speech before starting new speech
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        
        // Map language codes to BCP-47 codes for AVSpeechSynthesisVoice
        let voiceLanguageCode: String
        switch language.lowercased() {
        case "en":
            voiceLanguageCode = "en-US" // Or en-GB, en-AU, etc.
        case "es":
            voiceLanguageCode = "es-ES" // Or es-MX, etc.
        // Add more language mappings as needed
        default:
            voiceLanguageCode = "en-US" // Default to English
        }
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguageCode)
        
        // You can adjust rate, pitch, volume if desired
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate // Or a float like 0.5 for slower, 1.5 for faster
        // utterance.pitchMultiplier = 1.0
        // utterance.volume = 1.0
        
        print("SpeechManager: Attempting to speak in \(voiceLanguageCode): \(text.prefix(50))...")
        synthesizer.speak(utterance)
        // isSpeaking will be set to true by the delegate method `didStart`
    }

    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word) // .immediate or .word
            print("SpeechManager: Pause requested.")
            // isPaused and isSpeaking will be updated by delegate methods
        }
    }

    func resume() {
        // Check both synthesizer's state and our own isPaused state
        if synthesizer.isPaused && isPaused {
            synthesizer.continueSpeaking()
            print("SpeechManager: Resume requested.")
            // isSpeaking and isPaused will be updated by delegate methods
        }
    }

    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
            print("SpeechManager: Stop requested.")
            // isSpeaking and isPaused will be set to false by delegate `didFinish` or `didCancel`
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate methods
    // These methods are called on a background thread, so UI updates must be dispatched to the main actor.

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
            self.isPaused = false
            print("SpeechDelegate: didStart")
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            print("SpeechDelegate: didFinish")
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false // Synthesizer is no longer actively speaking
            self.isPaused = true
            print("SpeechDelegate: didPause")
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
            self.isPaused = false
            print("SpeechDelegate: didContinue")
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            print("SpeechDelegate: didCancel")
        }
    }
}
