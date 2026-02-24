//
//  SkeletonVideoPlayer.swift
//  TailTranslate
//
//  Created by Theodore Utomo on 2/23/26.
//

import SwiftUI
import AVKit
import AVFoundation
import UIKit

/// A reusable view that plays a video and overlays an animal skeleton that tracks the animal in real time
@available(iOS 17.0, *)
struct SkeletonVideoPlayer: View {
    let url: URL
    let isSkeletonOn: Bool
    // Callback for when the video playback starts
    let onPlaybackStarted: (() -> Void)?

    @StateObject private var poseDetector = AnimalPoseDetector()
    @State private var player: AVPlayer?
    @State private var videoNaturalSize: CGSize?

    var body: some View {
        GeometryReader { geo in
            let viewSize = CGSize(width: max(geo.size.width, 1), height: max(geo.size.height, 1))
            let contentSize = aspectFitSize(
                natural: videoNaturalSize ?? viewSize,
                within: viewSize
            )
            ZStack {
                if let player = player {
                    VideoPlayer(player: player)
                        .frame(width: viewSize.width, height: viewSize.height)
                } else {
                    Color.gray.opacity(0.3)
                        .frame(width: viewSize.width, height: viewSize.height)
                }
                if isSkeletonOn {
                    AnimalSkeletonView(animalJoint: poseDetector, size: contentSize)
                        .frame(width: contentSize.width, height: contentSize.height)
                        .allowsHitTesting(false)
                }
            }
        }
        .task { await runLiveSkeleton() }
    }

    // Live frame loop

    private func runLiveSkeleton() async {
        let p = AVPlayer(url: url)

        let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        p.currentItem?.add(videoOutput)

        let asset = AVAsset(url: url)
        let orientation = await videoOrientation(for: asset)

        await MainActor.run { player = p }

        let context = CIContext()
        let interval: UInt64 = 200_000_000 // 0.2s

        var didReportPlayback = false
        while !Task.isCancelled {
            let time = await MainActor.run { p.currentTime() }
            let isPlaying = await MainActor.run { p.rate > 0 }
            if !didReportPlayback, isPlaying {
                didReportPlayback = true
                await MainActor.run { onPlaybackStarted?() }
            }

            if videoOutput.hasNewPixelBuffer(forItemTime: time),
               let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) {
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
                    let displaySize = displaySize(for: cgImage, orientation: orientation)
                    await MainActor.run {
                        if videoNaturalSize == nil { videoNaturalSize = displaySize }
                        poseDetector.processImage(image)
                    }
                }
            }

            try? await Task.sleep(nanoseconds: interval)
        }
    }

    // Helpers

    private func videoOrientation(for asset: AVAsset) async -> UIImage.Orientation {
        guard let track = try? await asset.loadTracks(withMediaType: .video).first,
              let transform = try? await track.load(.preferredTransform) else {
            return .up
        }
        let a = transform.a, b = transform.b, c = transform.c, d = transform.d
        if a == 0 && b == 1 && c == -1 && d == 0 { return .right }
        if a == 0 && b == -1 && c == 1 && d == 0 { return .left }
        if a == -1 && b == 0 && c == 0 && d == -1 { return .down }
        return .up
    }

    private func displaySize(for cgImage: CGImage, orientation: UIImage.Orientation) -> CGSize {
        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        switch orientation {
        case .left, .right, .leftMirrored, .rightMirrored:
            return CGSize(width: h, height: w)
        default:
            return CGSize(width: w, height: h)
        }
    }

    private func aspectFitSize(natural: CGSize, within bounds: CGSize) -> CGSize {
        guard natural.width > 0, natural.height > 0 else { return bounds }
        let scale = min(bounds.width / natural.width, bounds.height / natural.height)
        return CGSize(width: natural.width * scale, height: natural.height * scale)
    }
}
