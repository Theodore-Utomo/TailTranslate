//
//  ContentView.swift
//  TailTranslate
//
//  Created by Theodore Utomo on 2/16/26.
//

import SwiftUI
import PhotosUI

@available(iOS 17.0, *)
struct ContentView: View {
    @StateObject var animalJoint = AnimalPoseDetector()
    @State private var selectedImage: UIImage? = UIImage(named: "cat_starter")
    @State private var pickerItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                ZStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 25))                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.black, lineWidth: 4)
                            )
                            .clipped()
                        
                        AnimalSkeletonView(animalJoint: animalJoint, size: geo.size)
                    } else {
                        ContentUnavailableView("No Image Selected", systemImage: "photo")
                    }
                }
            }
            .frame(height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding()
            
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Select Photo", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
            }
            .onChange(of: pickerItem) {
                Task {
                    if let data = try? await pickerItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        animalJoint.processImage(uiImage)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            if let img = selectedImage {
                animalJoint.processImage(img)
            }
        }
    }
}
