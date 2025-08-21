//
//  OnboardingFlowView.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/8/20.
//


// OnboardingFlowView.swift

import SwiftUI

// This is the main container that manages the entire onboarding sequence.
struct OnboardingFlowView: View {
    // This enum helps us track which screen to show.
    enum OnboardingStep {
        case intro, startTest, questionnaire, results
    }
    @Binding var didComplete: Bool

    @State private var currentStep: OnboardingStep = .intro
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            // Use the background color from your theme
            // Note: You'll need access to your ThemeManager for this to work.
            // For now, we'll use a placeholder.
            Color(UIColor.systemGray6).ignoresSafeArea()

            switch currentStep {
            case .intro:
                OnboardingIntroView(
                    onKnowMeBetter: { currentStep = .startTest },
                    onSkip: { didComplete = true }
                )
            case .startTest:
                OnboardingStartTestView(
                    onStartTest: { currentStep = .questionnaire }
                )
            case .questionnaire:
                QuestionnaireView(
                    viewModel: viewModel,
                    onSkip: {
                        viewModel.skipTest()
                        didComplete = true
                    }
                )
            case .results:
                OnboardingResultsView(
                    result: viewModel.result,
                    onComplete: {
                        print("Final button tapped. Setting didComplete to true.")
                        didComplete = true
                    }
                )
            }
        }
        .task {
            await viewModel.loadPersonalityResults(locale: "en")
            await viewModel.loadPersonalityQuestions(locale: "en")
            await viewModel.loadPersonalityResults(locale: "en")
        }
        .onChange(of: viewModel.quizCompleted) { completed in
            // When the view model marks the quiz as complete, show the results.
            if completed {
                currentStep = .results
            }
        }
    }
}

// MARK: - Welcome Screen (image_caf1ee.png)
struct OnboardingIntroView: View {
    var onKnowMeBetter: () -> Void
    var onSkip: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            // Replace with your actual logo if available
            Image("applogo-\(themeManager.currentTheme.id)")
                .resizable()
                .scaledToFit()
                .frame(height: 120) // Adjust the height as needed for your logo's aspect ratio
            Text("Welcome to\nGenius Parenting")
                .font(.largeTitle).bold()
                .multilineTextAlignment(.center)
            
            Text("Your AI-powered partner in building trust, love, and resilience in parenting.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("You already know your child best. In 30 seconds, help us know you — so your parenting support is as smart and unique as you are.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Button("Know me Better", action: onKnowMeBetter)
                    .buttonStyle(PrimaryButtonStyle())
                
                Button("Skip", action: onSkip)
                    .buttonStyle(SecondaryButtonStyle())
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Start Test Screen (image_caf227.png)
struct OnboardingStartTestView: View {
    var onStartTest: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("applogo-\(themeManager.currentTheme.id)")
                .resizable()
                .scaledToFit()
                .frame(height: 120) // Adjust the height as needed for your logo's aspect ratio
            Spacer()
            Text("Great! Let's get to know you better. This will only take 30 seconds.")
                .font(.title2).bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button("Start Personality Test", action: onStartTest)
                .buttonStyle(PrimaryButtonStyle())
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Questionnaire Screen (image_caf269.png)
struct QuestionnaireView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onSkip: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        if viewModel.isLoadingQuestions {
            VStack { Spacer(); ProgressView("Loading questions…"); Spacer() }
                .padding()
        } else if let err = viewModel.questionsError {
            VStack(spacing: 12) {
                Text("Failed to load questions").font(.headline)
                Text(err).font(.footnote).foregroundColor(.secondary)
                Button("Retry") { Task { await viewModel.loadPersonalityQuestions(locale: "en") } }
                    .buttonStyle(PrimaryButtonStyle())
            }.padding()
        } else if viewModel.questions.isEmpty {
            VStack { Spacer(); Text("No questions available."); Spacer() }.padding()
        } else {
            // ——— your original questionnaire UI ———
            VStack(alignment: .leading, spacing: 30) {
                Text("Question \(viewModel.currentQuestionIndex + 1)")
                    .font(.title).bold()
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(viewModel.currentQuestion.questionText)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)

                ForEach(viewModel.currentQuestion.answers) { answer in
                    Button(action: { viewModel.selectAnswer(answer) }) {
                        HStack(spacing: 20) {
                            Text(answer.ans_id)     // ← letter badge
                                .font(.headline)
                                .padding(.horizontal)

                            Rectangle()
                                .fill(Color.primary.opacity(0.5))
                                .frame(width: 1)

                            Text(answer.ans_text)   // ← display text
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Spacer()
                        }
                        .padding()
                        .frame(minHeight: 80)
                        .background(themeManager.currentTheme.background)
                        .foregroundColor(themeManager.currentTheme.accent)
                        .cornerRadius(12)
                    }
                }
                Spacer()
                HStack {
                    Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Skip Test >", action: onSkip)
                        .foregroundColor(themeManager.currentTheme.accent)
                }
            }
            .padding()
        }
    }
}

// MARK: - Results Screen (image_caf2c2.png)
struct OnboardingResultsView: View {
    let result: QuizResult
    var onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss   // ← add this

    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Results")
                .font(.title2).bold()
            
            Text(result.title)
                .font(.largeTitle).bold()
                .foregroundColor(themeManager.currentTheme.accent)
                .multilineTextAlignment(.center)
            
            Text(result.description)
                .multilineTextAlignment(.center)
            
            VStack {
                Text("Your Power Tip:")
                    .font(.headline)
                
                // Placeholder for the image
                if let url = result.imageURL {
                    CachedAsyncImage(url: url)       // uses your ImageCache for performance
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Image("family_funny_faces")      // fallback asset
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                Text(result.powerTip)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 5)
            
            Spacer()
            
            Button("Watch My Parenting Tip Video") {
                            print("Final button tapped. Setting didComplete to true.")
                            onComplete()   // ← call the closure (sets the binding in the parent)
                            dismiss()      // ← then close the fullscreen cover immediately
                        }
                        .buttonStyle(PrimaryButtonStyle())
            Spacer()
        }
        .padding()
    }
}

