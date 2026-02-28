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
    @State private var showMain = true

    var body: some View {
        NavigationStack {
            IntroView(onContinue: { showMain = true })
                .navigationDestination(isPresented: $showMain) {
                    MainContentView(animalJoint: animalJoint)
                }
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
