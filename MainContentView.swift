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
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("TailTranslate")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(.indigo)
                            Text("Upload a photo to decode their body language")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 12)

                        ImageAnalysisView(
                            selectedImage: selectedImage,
                            isSkeletonOn: isSkeletonOn,
                            animalJoint: animalJoint
                        )

                        if let detected = animalJoint.animalDetected, !detected, selectedImage != nil {
                            NoAnimalDetectedBanner()
                        }

                        // Controls card
                        VStack(spacing: 14) {
                            HStack {
                                Label("Skeleton Overlay", systemImage: "figure.cat.circle")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                Spacer()
                                Toggle("", isOn: $isSkeletonOn)
                                    .labelsHidden()
                                    .tint(.indigo)
                            }

                            Divider()

                            PhotoPickerBar(
                                pickerItem: $pickerItem,
                                showSamples: $showSamples,
                                onImageSelected: selectImage
                            )

                            if showSamples {
                                SamplePhotosGrid(onSelect: selectImage)
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        if animalJoint.animalDetected == true {
                            BodyLanguageSection(parts: animalJoint.animalBodyParts)
                        }
                    }
                    .padding(.bottom, 32)
                }
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
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(.separator), lineWidth: 1)
                        )

                    if isSkeletonOn {
                        AnimalSkeletonView(animalJoint: animalJoint, size: fittedSize)
                            .frame(width: fittedSize.width, height: fittedSize.height)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.tertiary)
                                Text("No Image Selected")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        )
                }
            }
        }
        .frame(height: 400)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
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
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            Text("No animal detected — try a photo with a cat or dog in a clear pose.")
                .font(.system(.subheadline, design: .rounded))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}


@available(iOS 17.0, *)
private struct PhotoPickerBar: View {
    @Binding var pickerItem: PhotosPickerItem?
    @Binding var showSamples: Bool
    var onImageSelected: (UIImage) -> Void

    var body: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.indigo)
                    )
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
                Label(showSamples ? "Hide Samples" : "Sample Photos", systemImage: "photo.stack")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .foregroundStyle(.indigo)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.indigo, lineWidth: 1.5)
                    )
            }
        }
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
            HStack(spacing: 10) {
                ForEach(samplePhotos, id: \.name) { photo in
                    if let url = Bundle.main.url(forResource: photo.name, withExtension: photo.ext),
                       let data = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
                            .onTapGesture { onSelect(uiImage) }
                    }
                }
            }
            .padding(.top, 4)
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
            HStack(spacing: 6) {
                Image(systemName: "text.magnifyingglass")
                    .foregroundStyle(.indigo)
                Text("Body Language Analysis")
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
            .padding(.horizontal)

            ForEach(insights) { insight in
                InsightCard(insight: insight)
            }
        }
        .padding(.top, 4)
    }
}

private struct InsightCard: View {
    let insight: BodyLanguageInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(insight.title)
                .font(.system(.headline, design: .rounded))
            Text(insight.detail)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}
