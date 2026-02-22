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

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Title
            Text("Welcome to Tail Translate")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Description
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
