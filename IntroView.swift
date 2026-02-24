//
//  IntroView.swift
//  TailTranslate
//
//  Created by Theodore Utomo on 2/22/26.
//

import SwiftUI
import UIKit

@available(iOS 17.0, *)
struct IntroView: View {
    @State private var isSkeletonOn: Bool = false
    @State private var step: IntroStep = .promptPlay
    
    let deviceWidth = UIScreen.main.bounds.width

    var onContinue: () -> Void

    private var introVideoURL: URL? {
        Bundle.main.url(forResource: "FrankieTree", withExtension: "MOV")
    }

    private enum IntroStep: Int, CaseIterable {
        case promptPlay           // "Tap the video to start"
        case videoPlaying         // "This is my cat Frankie..."
        case promptToggle         // "Want to see a visual outline... Click the toggle"
        case afterToggle          // "Animal body language is fascinating..."
        case readyToStart         // "Let's get started..." + Get Started button
    }

    @ViewBuilder
    private var stepText: some View {
        switch step {
        case .promptPlay:
            Text("Tap the video below to start playing and meet Frankie!")
                .font(.title2)
                .fontWeight(.semibold)
        case .videoPlaying:
            Text("This is my cat Frankie. Watch how she is exploring.")
        case .promptToggle:
            Text("Want to see a visual outline of her body? Click the toggle button below.")
        case .afterToggle:
            Text("Animal body language is fascinating, and we can use it to tell a lot about their emotions.")
        case .readyToStart:
            Text("Let's get started to see how we analyze cat body language.")
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                stepText
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .transition(.push(from: .trailing))
                    .id(step)
            }
            .frame(height: 80, alignment: .center)
            .clipped()
            .animation(.easeInOut(duration: 0.4), value: step)

            if let url = introVideoURL {
                SkeletonVideoPlayer(url: url, isSkeletonOn: isSkeletonOn) {
                    onVideoPlaybackStarted()
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
            }

            Toggle("Toggle Animal Skeleton Overlay", isOn: $isSkeletonOn)
                .padding()
                .opacity(step.rawValue >= IntroStep.promptToggle.rawValue ? 1 : 0.6)
                .disabled(step.rawValue < IntroStep.promptToggle.rawValue)
                .onChange(of: isSkeletonOn) { _, newValue in
                    if step == .promptToggle, newValue {
                        step = .afterToggle
                        scheduleReadyToStart()
                    }
                }

            Spacer()

            Group {
                if step == .readyToStart {
                    Button(action: onContinue) {
                        Label("Get Started", systemImage: "photo.on.rectangle.angled")
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: step == .readyToStart)
            .padding(.bottom, 12)
        }
    }

    private func onVideoPlaybackStarted() {
        guard step == .promptPlay else { return }
        withAnimation { step = .videoPlaying }
        scheduleTogglePrompt()
    }

    private func scheduleTogglePrompt() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_500_000_000) // ~4.5 seconds
            guard step == .videoPlaying else { return }
            withAnimation { step = .promptToggle }
        }
    }

    private func scheduleReadyToStart() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000) // 4 seconds
            guard step == .afterToggle else { return }
            withAnimation { step = .readyToStart }
        }
    }
}
