//
//  AnimalPoseDetector.swift
//  TailTranslate
//
//  Created by Theodore Utomo on 2/16/26.
//

import AVFoundation
import Vision
import UIKit

extension UIImage {
    var visionOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

@available(iOS 17.0, *)
class AnimalPoseDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    @Published var animalBodyParts = [VNAnimalBodyPoseObservation.JointName: VNRecognizedPoint]()
    
    func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let orientation = image.visionOrientation
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
        let request = VNDetectAnimalBodyPoseRequest(completionHandler: detectedAnimalPose)
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the request: \(error).")
        }
    }
    
    func detectedAnimalPose(request: VNRequest, error: Error?) {
        // Get the results from VNAnimalBodyPoseObservations.
        guard let animalBodyPoseResults = request.results as? [VNAnimalBodyPoseObservation] else { return }
        // Get the animal body recognized points for the .all group.
        guard let animalBodyAllParts = try? animalBodyPoseResults.first?.recognizedPoints(.all) else { return }
        self.animalBodyParts = animalBodyAllParts
    }
}
