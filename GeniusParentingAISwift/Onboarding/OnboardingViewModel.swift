//
//  OnboardingViewModel.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/8/20.
//
// OnboardingViewModel.swift

import Foundation
import Combine

class OnboardingViewModel: ObservableObject {
    private let logger = AppLogger(category: "OnboardingViewModel") // ✅ add this
    @Published var currentQuestionIndex = 0
    @Published var userSelections: [String: String] = [:]
    @Published var quizCompleted = false

    // Results (already present)
    @Published var remoteResults: [PersonalityResult] = []
    @Published var isLoadingResults = false
    @Published var loadError: String?

    // NEW: Questions state
    @Published var questions: [Question] = []
    @Published var isLoadingQuestions = false
    @Published var questionsError: String?

    // Load Strapi results (unchanged)
    @MainActor
    func loadPersonalityResults(locale: String = "en") async {   // ← remove the duplicated @MainActor
        isLoadingResults = true
        loadError = nil
        defer { isLoadingResults = false }
        do {
            let list = try await StrapiService.shared.fetchPersonalityResults(locale: locale, pageSize: 50)
            self.remoteResults = list.data ?? []
            logger.info("[OnboardingVM] Loaded \(self.remoteResults.count) results.")   // ← add self
            self.remoteResults.forEach { r in                                            // ← add self
                logger.info("[OnboardingVM] result id=\(r.id) ps_id=\(r.attributes.psId ?? "nil") title='\(r.attributes.title)' image='\(r.attributes.image?.data?.attributes.url ?? "nil")'")
            }
        } catch {
            self.loadError = error.localizedDescription
            logger.error("[OnboardingVM] Failed loading results: \(error.localizedDescription)")
        }
    }
    // NEW: Load questions
    @MainActor
    func loadPersonalityQuestions(locale: String = "en") async {
        guard !isLoadingQuestions else { return }
        isLoadingQuestions = true
        questionsError = nil
        defer { isLoadingQuestions = false }                     // ← ensures flag resets on error too
        do {
            let list = try await StrapiService.shared.fetchPersonalityQuestions(locale: locale, pageSize: 100)
            let items = (list.data ?? []).sorted { $0.attributes.order < $1.attributes.order }
            self.questions = items.map(Question.init(from:))
            self.currentQuestionIndex = 0
            self.userSelections = [:]
        } catch {
            self.questionsError = error.localizedDescription
        }
    }

    // Safe currentQuestion
    var currentQuestion: Question {
        guard !questions.isEmpty, currentQuestionIndex >= 0, currentQuestionIndex < questions.count
        else { return Question(questionText: "Loading…", answers: []) }
        return questions[currentQuestionIndex]
    }

    func selectAnswer(_ answer: Answer) {
        // Use question index as the key; you can switch to a stable id if you add one to Question
        let qKey = "q\(currentQuestionIndex)"
        userSelections[qKey] = answer.ans_id  // ← store A/B/C/D for scoring

        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            quizCompleted = true
        }
    }

    func skipTest() { quizCompleted = true }
    
    
    // 1) Decide the letter by your rules
    private func decideLetterByRules() -> String {
        // Count A/B/C/D
        let all = Array(userSelections.values)
        let a = all.filter { $0 == "A" }.count
        let b = all.filter { $0 == "B" }.count
        let c = all.filter { $0 == "C" }.count
        let d = all.filter { $0 == "D" }.count

        // Mostly X’s = count >= 3
        if a >= 3 { return "A" }
        if b >= 3 { return "B" }
        if c >= 3 { return "C" }
        if d >= 3 { return "D" }

        // Explicit 2+2 ties (your specified precedence)
        if a == 2 && b == 2 { return "A" } // A > B
        if b == 2 && c == 2 { return "B" } // B > C
        if c == 2 && d == 2 { return "C" } // C > D
        if a == 2 && d == 2 { return "A" } // A > D

        // Any other 2+2 (e.g., A+C or B+D): pick earliest by A > B > C > D
        if [a,b,c,d].contains(2), [a,b,c,d].filter({ $0 == 2 }).count == 2 {
            for letter in ["A","B","C","D"] {
                let count = (letter == "A" ? a : letter == "B" ? b : letter == "C" ? c : d)
                if count == 2 { return letter }
            }
        }

        // Full tie / fallback → Mindful Mixer (A first in order)
        return "A"
    }

    // 2) Map letter → Strapi ps_id ("1"..."4")
    private func psIdForLetter(_ letter: String) -> String {
        switch letter {
        case "A": return "1" // Mindful Mixer
        case "B": return "2" // Respectful Rock
        case "C": return "3" // Creative Flow
        case "D": return "4" // Chill Guardian
        default:  return "1"
        }
    }

    // 3) Use Strapi-backed results when available
    var result: QuizResult {
        let letter = decideLetterByRules()
        let psId = psIdForLetter(letter)
        logger.info("[OnboardingVM] decideLetterByRules -> \(letter), mapping to ps_id=\(psId)")

        if let match = remoteResults.first(where: { $0.attributes.psId == psId }) {
            let path = match.attributes.image?.data?.attributes.url
            // normalize base url (avoid double slashes)
            let base = Config.strapiBaseUrl.hasSuffix("/") ? String(Config.strapiBaseUrl.dropLast()) : Config.strapiBaseUrl
            let url: URL? = {
                guard let p = path else { return nil }
                if p.hasPrefix("http") { return URL(string: p) }
                return URL(string: base + p)
            }()
            logger.info("[OnboardingVM] chosen id=\(match.id) title='\(match.attributes.title)' imagePath='\(path ?? "nil")' imageURL='\(url?.absoluteString ?? "nil")'")

            return QuizResult(
                title: match.attributes.title,
                description: match.attributes.description,
                powerTip: match.attributes.powerTip,
                imageURL: url
            )
        }

        logger.info("[OnboardingVM] No remote match found; returning fallback result.")
        return QuizResult(
            title: "You're the Mindful Mixer",
            description: "Calm-ish. Thoughtful. Reflective.\nYou pause before yelling. You talk things out. You're raising an emotionally smart little human.",
            powerTip: "Not everything needs a deep convo—sometimes a funny face works faster.",
            imageURL: nil
        )
    }

}
