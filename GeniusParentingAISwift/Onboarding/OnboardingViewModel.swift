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
    // Published properties will trigger UI updates when they change
    @Published var currentQuestionIndex = 0
    @Published var userSelections: [String: String] = [:] // [QuestionID: AnswerID]
    @Published var quizCompleted = false
    @Published var remoteResults: [PersonalityResult] = []
    @Published var isLoadingResults = false
    @Published var loadError: String?

    @MainActor
    func loadPersonalityResults(locale: String = "en") async {
        guard !isLoadingResults else { return }
        isLoadingResults = true
        loadError = nil
        do {
            let list = try await StrapiService.shared.fetchPersonalityResults(locale: locale)
            self.remoteResults = list.data ?? []
        } catch {
            self.loadError = error.localizedDescription
        }
        isLoadingResults = false
    }

    // Example mapping: dominant choice A/B/C/D → ps_id "1"..."4"
    private func inferredPSId() -> String {
        let counts = ["A","B","C","D"].reduce(into: [String:Int]()) { acc, k in
            acc[k] = userSelections.values.filter { $0 == k }.count
        }
        let best = counts.max { $0.value < $1.value }?.key ?? "A"
        switch best { case "A": return "1"; case "B": return "2"; case "C": return "3"; case "D": return "4"; default: return "1" }
    }

    var result: QuizResult {
        if let match = remoteResults.first(where: { $0.attributes.psId == inferredPSId() }) {
            return QuizResult(from: match)
        }
        // Fallback to your current hardcoded result if API not loaded yet
        return QuizResult(
            title: "You're the Mindful Mixer",
            description: "Calm-ish. Thoughtful. Reflective.\nYou pause before yelling. You talk things out. You're raising an emotionally smart little human.",
            powerTip: "Not everything needs a deep convo—sometimes a funny face works faster."
        )
    }
    
    // Your list of questions. Based on your mockups.
    let questions: [Question] = [
        Question(questionText: "Your kid just spilled juice everywhere. What do you do first?", answers: [
            Answer(id: "A", text: "Grab a towel and talk them through it."),
            Answer(id: "B", text: "Say, “This is why we don’t play with cups!”"),
            Answer(id: "C", text: "Laugh it off and grab your phone for a quick photo."),
            Answer(id: "D", text: "Clean up quietly—no big deal.")
        ]),
        Question(questionText: "Bedtime is a mess. How do you handle it?", answers: [
            Answer(id: "A", text: "We have a bedtime chart—it works most nights."),
            Answer(id: "B", text: "I tell them it’s lights out or no cartoons tomorrow!"),
            Answer(id: "C", text: "We dance, hug, argue, and then sleep. Chaos is normal."),
            Answer(id: "D", text: "Eventually, we get there… usually on the couch.")
        ]),
        // Add your other 3 questions here...
        Question(questionText: "Question 3: Placeholder?", answers: [
            Answer(id: "A", text: "Answer A"), Answer(id: "B", text: "Answer B"),
            Answer(id: "C", text: "Answer C"), Answer(id: "D", text: "Answer D")
        ]),
        Question(questionText: "Question 4: Placeholder?", answers: [
            Answer(id: "A", text: "Answer A"), Answer(id: "B", text: "Answer B"),
            Answer(id: "C", text: "Answer C"), Answer(id: "D", text: "Answer D")
        ]),
        Question(questionText: "Question 5: Placeholder?", answers: [
            Answer(id: "A", text: "Answer A"), Answer(id: "B", text: "Answer B"),
            Answer(id: "C", text: "Answer C"), Answer(id: "D", text: "Answer D")
        ])
    ]

    var currentQuestion: Question {
        questions[currentQuestionIndex]
    }

    func selectAnswer(_ answer: Answer) {
        let questionId = currentQuestion.id.uuidString
        userSelections[questionId] = answer.id
        
        // Move to the next question or finish the quiz
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            quizCompleted = true
            // Here you would save the final result, e.g., send it to your server
            print("Quiz finished with selections: \(userSelections)")
            print("Final Result: \(result.title)")
        }
    }
    
    func skipTest() {
        quizCompleted = true
        print("User skipped the test.")
    }
}
