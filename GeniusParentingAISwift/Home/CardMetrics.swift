//
//  CardMetrics.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/8/19.
//


// CardMetrics.swift
import SwiftUI

struct CardMetrics {
    var widthRatio: CGFloat = 0.85
    var height: CGFloat = 250
    var shadowAllowance: CGFloat = 12
}

private struct CardMetricsKey: EnvironmentKey {
    static let defaultValue = CardMetrics()
}

extension EnvironmentValues {
    var cardMetrics: CardMetrics {
        get { self[CardMetricsKey.self] }
        set { self[CardMetricsKey.self] = newValue }
    }
}

extension View {
    /// Use this to override sizes per screen / size class if you want.
    func cardMetrics(_ metrics: CardMetrics) -> some View {
        environment(\.cardMetrics, metrics)
    }
}
