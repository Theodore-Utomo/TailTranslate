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

    var onContinue: () -> Void

    private var introVideoURL: URL? {
        Bundle.main.url(forResource: "FrankieTree", withExtension: "MOV")
    }

    private enum IntroStep: Int, CaseIterable {
        case promptPlay
        case videoPlaying
        case promptToggle
        case afterToggle
        case readyToStart
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
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("TailTranslate")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.indigo)
                    .padding(.bottom, 4)

                Text("Understand what your cat is saying")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)

                ZStack {
                    stepText
                        .font(.system(.title3, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.push(from: .trailing))
                        .id(step)
                }
                .frame(height: 90, alignment: .center)
                .clipped()
                .animation(.easeInOut(duration: 0.4), value: step)

                if let url = introVideoURL {
                    SkeletonVideoPlayer(url: url, isSkeletonOn: isSkeletonOn, isMuted: true) {
                        onVideoPlaybackStarted()
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .padding(.horizontal, 24)
                }

                HStack {
                    Label("Skeleton Overlay", systemImage: "figure.cat.circle")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Toggle("", isOn: $isSkeletonOn)
                        .labelsHidden()
                        .tint(.indigo)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .opacity(step.rawValue >= IntroStep.promptToggle.rawValue ? 1 : 0.35)
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
                            HStack(spacing: 8) {
                                Image(systemName: "pawprint.fill")
                                Text("Get Started")
                            }
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.indigo)
                            )
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .animation(.easeInOut(duration: 0.35), value: step == .readyToStart)
                .padding(.bottom, 28)
            }
        }
    }

    private func onVideoPlaybackStarted() {
        guard step == .promptPlay else { return }
        withAnimation { step = .videoPlaying }
        scheduleTogglePrompt()
    }

    private func scheduleTogglePrompt() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            guard step == .videoPlaying else { return }
            withAnimation { step = .promptToggle }
        }
    }

    private func scheduleReadyToStart() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard step == .afterToggle else { return }
            withAnimation { step = .readyToStart }
        }
    }
}
