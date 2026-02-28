//
//  MainContentView.swift
//  TailTranslate
//
//  Created by Theodore Utomo on 2/22/26.
//

import SwiftUI
import PhotosUI
import Vision

@available(iOS 17.0, *)
struct MainContentView: View {
    @ObservedObject var animalJoint: AnimalPoseDetector
    @State private var selectedImage: UIImage? = {
        guard let url = Bundle.main.url(forResource: "Frankie1", withExtension: "jpg"),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }()
    @State private var pickerItem: PhotosPickerItem?
    @State private var showSamples = false
    @State private var isSkeletonOn = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Analyze Cat Body Language")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.top)

                    ImageAnalysisView(
                        selectedImage: selectedImage,
                        isSkeletonOn: isSkeletonOn,
                        animalJoint: animalJoint
                    )

                    if let detected = animalJoint.animalDetected, !detected, selectedImage != nil {
                        NoAnimalDetectedBanner()
                    }

                    Toggle("Skeleton Overlay", isOn: $isSkeletonOn)
                        .padding(.horizontal)

                    PhotoPickerBar(
                        pickerItem: $pickerItem,
                        showSamples: $showSamples,
                        onImageSelected: selectImage
                    )

                    if showSamples {
                        SamplePhotosGrid(onSelect: selectImage)
                    }

                    if animalJoint.animalDetected == true {
                        BodyLanguageSection(parts: animalJoint.animalBodyParts)
                    }
                }
                .padding(.bottom, 24)
            }
            .onAppear {
                if let img = selectedImage {
                    animalJoint.processImage(img)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func selectImage(_ image: UIImage) {
        selectedImage = image
        animalJoint.processImage(image)
    }
}


@available(iOS 17.0, *)
private struct ImageAnalysisView: View {
    let selectedImage: UIImage?
    let isSkeletonOn: Bool
    @ObservedObject var animalJoint: AnimalPoseDetector

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image = selectedImage {
                    let fittedSize = aspectFitSize(imageSize: image.size, within: geo.size)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.black, lineWidth: 4)
                        )
                        .clipped()

                    if isSkeletonOn {
                        AnimalSkeletonView(animalJoint: animalJoint, size: fittedSize)
                            .frame(width: fittedSize.width, height: fittedSize.height)
                    }
                } else {
                    ContentUnavailableView("No Image Selected", systemImage: "photo")
                }
            }
        }
        .frame(height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func aspectFitSize(imageSize: CGSize, within bounds: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}


private struct NoAnimalDetectedBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text("No animal detected — try a photo with a cat or dog in a clear pose.")
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}


@available(iOS 17.0, *)
private struct PhotoPickerBar: View {
    @Binding var pickerItem: PhotosPickerItem?
    @Binding var showSamples: Bool
    var onImageSelected: (UIImage) -> Void

    var body: some View {
        HStack(spacing: 16) {
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
                        onImageSelected(uiImage)
                    }
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showSamples.toggle()
                }
            } label: {
                Label("Sample Photos", systemImage: "photo.stack")
                    .font(.headline)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}


private struct SamplePhotosGrid: View {
    var onSelect: (UIImage) -> Void

    private let samplePhotos: [(name: String, ext: String)] = [
        ("Frankie1", "jpg"),
        ("Frankie2", "PNG"),
        ("Frankie3", "PNG"),
        ("Frankie4", "PNG")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(samplePhotos, id: \.name) { photo in
                    if let url = Bundle.main.url(forResource: photo.name, withExtension: photo.ext),
                       let data = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.purple.opacity(0.4), lineWidth: 2)
                            )
                            .onTapGesture { onSelect(uiImage) }
                    }
                }
            }
            .padding(.horizontal)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}


@available(iOS 17.0, *)
private struct BodyLanguageSection: View {
    let parts: [VNAnimalBodyPoseObservation.JointName: VNRecognizedPoint]

    var body: some View {
        let insights = BodyLanguageAnalyzer.analyze(parts: parts)

        VStack(alignment: .leading, spacing: 12) {
            Text("Body Language Analysis")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            ForEach(insights) { insight in
                InsightCard(insight: insight)
            }
        }
        .padding(.top, 8)
    }
}

private struct InsightCard: View {
    let insight: BodyLanguageInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(insight.title)
                .font(.headline)
            Text(insight.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
