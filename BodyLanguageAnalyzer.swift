//
//  BodyLanguageAnalyzer.swift
//  TailTranslate
//
//  Created by Theodore Utomo on 2/23/26.
//

import Vision
import Foundation

struct BodyLanguageInsight: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

@available(iOS 17.0, *)
enum BodyLanguageAnalyzer {

    static func analyze(
        parts: [VNAnimalBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> [BodyLanguageInsight] {
        var insights: [BodyLanguageInsight] = []

        if let tailInsight = analyzeTail(parts: parts) {
            insights.append(tailInsight)
        }
        if let earInsight = analyzeEars(parts: parts) {
            insights.append(earInsight)
        }
        if let postureInsight = analyzePosture(parts: parts) {
            insights.append(postureInsight)
        }
        if let legInsight = analyzeLegs(parts: parts) {
            insights.append(legInsight)
        }

        if insights.isEmpty {
            insights.append(BodyLanguageInsight(
                title: "Analyzing...",
                detail: "Not enough visible joints to determine body language. Try a clearer photo."
            ))
        }

        return insights
    }


    private static func analyzeTail(
        parts: [VNAnimalBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> BodyLanguageInsight? {
        guard let tailBottom = parts[.tailBottom],
              let tailTop = parts[.tailTop],
              tailBottom.confidence > 0.1, tailTop.confidence > 0.1 else { return nil }

        let dy = tailTop.location.y - tailBottom.location.y
        let dx = tailTop.location.x - tailBottom.location.x

        if dy > 0.06 {
            return BodyLanguageInsight(
                title: "Tail Up: Confident & Happy",
                detail: "A raised tail is one of the clearest signs of a content, friendly cat. They're feeling social and approachable."
            )
        } else if dy < -0.06 {
            return BodyLanguageInsight(
                title: "Tail Down: Nervous or Submissive",
                detail: "A lowered or tucked tail can indicate fear, anxiety, or submission. The cat may feel insecure about their surroundings."
            )
        } else if abs(dx) > 0.08 && abs(dy) < 0.04 {
            return BodyLanguageInsight(
                title: "Tail Extended: Alert & Curious",
                detail: "A horizontally held tail suggests the cat is focused on something. They're assessing the situation with interest."
            )
        }

        return nil
    }


    private static func analyzeEars(
        parts: [VNAnimalBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> BodyLanguageInsight? {
        guard let leftEarTop = parts[.leftEarTop],
              let leftEarBottom = parts[.leftEarBottom],
              leftEarTop.confidence > 0.1, leftEarBottom.confidence > 0.1 else { return nil }

        let earDy = leftEarTop.location.y - leftEarBottom.location.y

        if earDy > 0.02 {
            return BodyLanguageInsight(
                title: "Ears Forward: Curious & Engaged",
                detail: "Upright, forward-facing ears mean the cat is alert and interested. They're actively paying attention to something."
            )
        } else if earDy < -0.01 {
            return BodyLanguageInsight(
                title: "Ears Flattened: Fearful or Agitated (Airplane Ears)",
                detail: "Flattened or pinned-back ears are a defensive signal. The cat may be scared, irritated, or preparing for conflict."
            )
        }

        return nil
    }


    private static func analyzePosture(
        parts: [VNAnimalBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> BodyLanguageInsight? {
        guard let neck = parts[.neck],
              let tailBottom = parts[.tailBottom],
              neck.confidence > 0.1, tailBottom.confidence > 0.1 else { return nil }

        let spineLength = hypot(
            neck.location.x - tailBottom.location.x,
            neck.location.y - tailBottom.location.y
        )

        let neckHeight = neck.location.y

        if neckHeight > 0.65 && spineLength > 0.15 {
            return BodyLanguageInsight(
                title: "Upright Posture: Confident",
                detail: "The cat is standing tall with a raised head. This signals confidence and alertness."
            )
        } else if neckHeight < 0.35 {
            return BodyLanguageInsight(
                title: "Low Posture: Crouching",
                detail: "A crouched or low posture can mean the cat is stalking prey, feeling cautious, or trying to appear smaller to avoid attention."
            )
        }

        return nil
    }


    private static func analyzeLegs(
        parts: [VNAnimalBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> BodyLanguageInsight? {
        guard let leftFrontPaw = parts[.leftFrontPaw],
              let rightFrontPaw = parts[.rightFrontPaw],
              leftFrontPaw.confidence > 0.1, rightFrontPaw.confidence > 0.1 else { return nil }

        let pawSpread = abs(leftFrontPaw.location.x - rightFrontPaw.location.x)

        if pawSpread > 0.2 {
            return BodyLanguageInsight(
                title: "Wide Stance: Assertive",
                detail: "A wide, planted stance makes the cat look bigger. This is a sign of confidence or territorial behavior."
            )
        } else if pawSpread < 0.05 {
            return BodyLanguageInsight(
                title: "Narrow Stance: Timid",
                detail: "Paws held close together can indicate uncertainty. The cat is making themselves smaller, likely feeling cautious."
            )
        }

        return nil
    }
}
