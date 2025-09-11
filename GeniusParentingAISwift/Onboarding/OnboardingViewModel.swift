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
    private let logger = AppLogger(category: "OnboardingViewModel")
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
    @Published var selectedResult: PersonalityResult?   // holds the chosen result with image
    @Published private var isPersisting = false

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
                let img = r.attributes.image?.data?.attributes.url ?? "nil"
                logger.info("[OnboardingVM] result id=\(r.id) ps_id=\(r.attributes.psId) title='\(r.attributes.title)' tip='\(r.attributes.powerTip)")            }
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
        // Prefer the single fetched result (comes with image populated)
        if let selected = selectedResult {
            let path = selected.attributes.image?.data?.attributes.url
            let base = Config.strapiBaseUrl.hasSuffix("/") ? String(Config.strapiBaseUrl.dropLast()) : Config.strapiBaseUrl
            let url: URL? = {
                guard let p = path else { return nil }
                if p.hasPrefix("http") { return URL(string: p) }
                return URL(string: base + p)
            }()

            return QuizResult(
                title: selected.attributes.title,
                description: selected.attributes.description,
                powerTip: selected.attributes.powerTip,
                imageURL: url
            )
        }

        // Fallback: use the lightweight list (may not include image)
        let letter = decideLetterByRules()
        let psId = psIdForLetter(letter)
        logger.info("[OnboardingVM] decideLetterByRules -> \(letter), mapping to ps_id=\(psId)")

        if let match = remoteResults.first(where: { $0.attributes.psId == psId }) {
            let path = match.attributes.image?.data?.attributes.url
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
    
    @MainActor
    func persistDisplayedResult(locale: String = "en") async {
        if isPersisting {
            logger.warning("[persistDisplayedResult] Already persisting. Ignoring duplicate call.")
            return
        }
        isPersisting = true
        defer { isPersisting = false }

        // 1) Prefer the displayed `selectedResult` (exactly what user sees)
        if let sel = selectedResult {
            logger.info("[persistDisplayedResult] Using selectedResult.id=\(sel.id) ps_id=\(sel.attributes.psId)")
            do {
                _ = try await StrapiService.shared.updateUserPersonalityResult(personalityResultId: sel.id)
                logger.info("[persistDisplayedResult] Update success with selectedResult.id=\(sel.id)")
                RefreshCoordinator.shared.markRecommendationsNeedsRefresh()
                return
            } catch {
                logger.error("[persistDisplayedResult] Update failed with selectedResult: \(error.localizedDescription)")
                return
            }
        }

        // 2) Fallback: compute once and persist that one
        let letter = decideLetterByRules()
        let psId = psIdForLetter(letter)
        logger.info("[persistDisplayedResult] No selectedResult. Using rules → letter=\(letter), ps_id=\(psId)")

        do {
            if let match = remoteResults.first(where: { $0.attributes.psId == psId }) {
                logger.info("[persistDisplayedResult] Persisting remoteResults match id=\(match.id)")
                _ = try await StrapiService.shared.updateUserPersonalityResult(personalityResultId: match.id)
            } else if let fetched = try await StrapiService.shared.fetchPersonalityResult(psId: psId, locale: locale) {
                logger.info("[persistDisplayedResult] Persisting fetched result id=\(fetched.id)")
                _ = try await StrapiService.shared.updateUserPersonalityResult(personalityResultId: fetched.id)
            } else {
                logger.error("[persistDisplayedResult] Could not resolve a result to persist.")
                return
            }

            logger.info("[persistDisplayedResult] Update success")
            RefreshCoordinator.shared.markRecommendationsNeedsRefresh()
        } catch {
            logger.error("[persistDisplayedResult] Update failed: \(error.localizedDescription)")
        }
    }
    
    
    // Persist the final (chosen) result to the user's profile in Strapi.
    // Uses the numeric Strapi id of the selected result.
    // Tries selectedResult first (already fetched with image); falls back to the list or a single fetch.
    @MainActor
    func persistFinalResultToProfile(locale: String = "en") async throws {
        let letter = decideLetterByRules()
        let psId = psIdForLetter(letter)
        logger.info("[OnboardingVM] persistFinalResultToProfile -> letter=\(letter), ps_id=\(psId)")

        // 1) If we already fetched the single result with image, use that id
        if let selected = selectedResult {
            _ = try await StrapiService.shared.updateUserPersonalityResult(personalityResultId: selected.id)
            logger.info("[OnboardingVM] Profile updated with selectedResult.id=\(selected.id)")
            return
        }

        // 2) If not, try to find it in the list we already loaded (no image, but has numeric id)
        if let match = remoteResults.first(where: { $0.attributes.psId == psId }) {
            _ = try await StrapiService.shared.updateUserPersonalityResult(personalityResultId: match.id)
            logger.info("[OnboardingVM] Profile updated with match.id=\(match.id)")
            return
        }

        // 3) Fallback: fetch the single result by ps_id (includes image) and take its id
        if let fetched = try await StrapiService.shared.fetchPersonalityResult(psId: psId, locale: locale) {
            _ = try await StrapiService.shared.updateUserPersonalityResult(personalityResultId: fetched.id)
            logger.info("[OnboardingVM] Profile updated with fetched.id=\(fetched.id)")
            return
        }

        logger.error("[OnboardingVM] Could not determine a result id to persist.")
        throw NSError(domain: "Onboarding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not determine result to save."])
    }
    @MainActor
    func prepareResultForDisplay(locale: String = "en") async {
        let letter = decideLetterByRules()
        let psId = psIdForLetter(letter)
        logger.info("[OnboardingVM] prepareResultForDisplay -> letter=\(letter), ps_id=\(psId)")
        do {
            if let single = try await StrapiService.shared.fetchPersonalityResult(psId: psId, locale: locale) {
                self.selectedResult = single
                logger.info("[OnboardingVM] selectedResult id=\(single.id) title='\(single.attributes.title)' image='\(single.attributes.image?.data?.attributes.url ?? "nil")'")
            }
        } catch {
            logger.error("[OnboardingVM] Failed to load selected result: \(error.localizedDescription)")
        }
    }

}
