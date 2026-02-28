//
//  AnimalSkeletonView.swift
//  TailTranslate
//
//  Created by Theodore Utomo on 2/16/26.
//

import SwiftUI
import Vision

@available(iOS 17.0, *)
struct AnimalSkeletonView: View {
    @ObservedObject var animalJoint: AnimalPoseDetector
    var size: CGSize

    private typealias JointName = VNAnimalBodyPoseObservation.JointName

    private struct Bone {
        let joints: [JointName]
        let color: Color
    }

    private let bones: [Bone] = [
        // Head (left)
        Bone(joints: [.nose, .leftEye], color: .orange),
        Bone(joints: [.leftEye, .leftEarBottom], color: .orange),
        Bone(joints: [.leftEarBottom, .leftEarMiddle, .leftEarTop], color: .orange),
        // Head (right)
        Bone(joints: [.nose, .rightEye], color: .orange),
        Bone(joints: [.rightEye, .rightEarBottom], color: .orange),
        Bone(joints: [.rightEarBottom, .rightEarMiddle, .rightEarTop], color: .orange),
        // Spine
        Bone(joints: [.nose, .neck], color: .yellow),
        Bone(joints: [.neck, .tailBottom], color: .green),
        // Front legs (left)
        Bone(joints: [.neck, .leftFrontElbow], color: .purple),
        Bone(joints: [.leftFrontElbow, .leftFrontKnee, .leftFrontPaw], color: .purple),
        // Front legs (right)
        Bone(joints: [.neck, .rightFrontElbow], color: .purple),
        Bone(joints: [.rightFrontElbow, .rightFrontKnee, .rightFrontPaw], color: .purple),
        // Back legs (left)
        Bone(joints: [.tailBottom, .leftBackElbow], color: .blue),
        Bone(joints: [.leftBackElbow, .leftBackKnee, .leftBackPaw], color: .blue),
        // Back legs (right)
        Bone(joints: [.tailBottom, .rightBackElbow], color: .blue),
        Bone(joints: [.rightBackElbow, .rightBackKnee, .rightBackPaw], color: .blue),
        // Tail
        Bone(joints: [.tailBottom, .tailMiddle, .tailTop], color: .orange),
    ]

    var body: some View {
        ZStack {
            if !animalJoint.animalBodyParts.isEmpty {
                drawBones()
                JointDotsView(parts: animalJoint.animalBodyParts, size: size)
            }
        }
    }

    @ViewBuilder
    private func drawBones() -> some View {
        let parts = animalJoint.animalBodyParts
        ZStack {
            ForEach(Array(bones.enumerated()), id: \.offset) { _, bone in
                let points = bone.joints.compactMap { parts[$0]?.location }
                if points.count == bone.joints.count {
                    BoneLine(points: points, size: size)
                        .stroke(lineWidth: 5.0)
                        .fill(bone.color)
                }
            }
        }
    }
}

@available(iOS 17.0, *)
private struct JointDotsView: View {
    let parts: [VNAnimalBodyPoseObservation.JointName: VNRecognizedPoint]
    let size: CGSize

    var body: some View {
        Canvas { context, _ in
            let transform = visionTransform(for: size)
            for (jointName, point) in parts {
                guard point.confidence > 0 else { continue }
                let pos = point.location.applying(transform)
                let dotSize: CGFloat = 8
                let rect = CGRect(
                    x: pos.x - dotSize / 2,
                    y: pos.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
                let color = Self.color(for: jointName)
                context.fill(Path(ellipseIn: rect), with: .color(color))
                context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 1.5)
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }

    private static func color(for joint: VNAnimalBodyPoseObservation.JointName) -> Color {
        switch joint {
        case .nose, .leftEye, .rightEye,
             .leftEarTop, .leftEarMiddle, .leftEarBottom,
             .rightEarTop, .rightEarMiddle, .rightEarBottom,
             .tailBottom, .tailMiddle, .tailTop:
            return .orange
        case .neck:
            return .yellow
        case .leftFrontElbow, .leftFrontKnee, .leftFrontPaw,
             .rightFrontElbow, .rightFrontKnee, .rightFrontPaw:
            return .purple
        case .leftBackElbow, .leftBackKnee, .leftBackPaw,
             .rightBackElbow, .rightBackKnee, .rightBackPaw:
            return .blue
        default:
            return .green
        }
    }
}

func visionTransform(for size: CGSize) -> CGAffineTransform {
    CGAffineTransform.identity
        .translatedBy(x: 0.0, y: -1.0)
        .concatenating(.identity.scaledBy(x: 1.0, y: -1.0))
        .concatenating(.identity.scaledBy(x: size.width, y: size.height))
}

struct BoneLine: Shape {
    var points: [CGPoint]
    var size: CGSize

    func path(in rect: CGRect) -> Path {
        let transform = visionTransform(for: size)
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first.applying(transform))
        for point in points.dropFirst() {
            path.addLine(to: point.applying(transform))
        }
        return path
    }
}
