//
//  IntroView.swift
//  TailTranslate
//
//  Created by Theodore Utomo on 2/22/26.
//

import SwiftUI

@available(iOS 17.0, *)
struct IntroView: View {
    var onContinue: () -> Void

    private var introVideoURL: URL? {
        Bundle.main.url(forResource: "FrankieTree", withExtension: "MOV")
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Welcome to Tail Translate")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                Text("See how animals communicate with their bodies.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                Text("Pick a photo to view the skeleton and learn body language.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            if let url = introVideoURL {
                SkeletonVideoPlayer(url: url)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
            }

            Spacer()

            Button(action: onContinue) {
                Label("Get Started", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}
