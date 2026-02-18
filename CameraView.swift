//
//  SwiftUIView.swift
//  TailTranslate
//
//  Created by Theodore Utomo on 2/16/26.
//

import SwiftUI

import UIKit
import AVFoundation

final class CameraView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    var previewLayer: AVCaptureVideoPreviewLayer {
        (layer as? AVCaptureVideoPreviewLayer)!
      }
}
