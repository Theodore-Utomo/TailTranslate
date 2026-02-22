//
//  ContentView.swift
//  TailTranslate
//
//  Created by Theodore Utomo on 2/16/26.
//

import SwiftUI

@available(iOS 17.0, *)
struct ContentView: View {
    @StateObject private var animalJoint = AnimalPoseDetector()
    @State private var hasCompletedIntro = false

    var body: some View {
        if hasCompletedIntro {
            MainContentView(animalJoint: animalJoint)
        } else {
            IntroView(onContinue: { hasCompletedIntro = true })
        }
    }
}
