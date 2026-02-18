//
//  CameraViewController.swift
//  TailTranslate
//
//  Created by Theodore Utomo on 2/16/26.
//

import UIKit
import AVFoundation
import Vision
import SwiftUI

final class CameraViewController: UIViewController {
    private var cameraSession: AVCaptureSession?
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    let cameraQueue = DispatchQueue(
        label: "CameraOutput",
        qos: .userInitiated
    )
    override func loadView() {
        view.self = CameraView()
    }
    var cameraView: CameraView {
        (view as? CameraView)!
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task {
            let granted = await isAuthorized
            
            if granted {
                do {
                    if cameraSession == nil {
                        try prepareAVSession()
                        cameraView.previewLayer.session = cameraSession
                        cameraView.previewLayer.videoGravity = .resizeAspectFill
                    }
                    
                    // Start session on a background thread
                    DispatchQueue.global(qos: .background).async {
                        self.cameraSession?.startRunning()
                    }
                } catch {
                    print("Session setup failed: \(error.localizedDescription)")
                }
            } else {
                print("Camera access was denied by the user.")
            }
            print("It worked!")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    
    func prepareAVSession() throws {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInDualCamera, .builtInWideAngleCamera]
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .back
        )
        
        // Select the back camera as a video device.
        guard let videoDevice = discoverySession.devices.first else {
            print("No camera found")
            return
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice)
        else { return }
        
        guard session.canAddInput(deviceInput)
        else { return }
        
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            dataOutput.setSampleBufferDelegate(delegate, queue: cameraQueue)
        } else { return }
        
        session.commitConfiguration()
        cameraSession = session
    }
}

@available(iOS 17.0, *)
struct DisplayView: UIViewControllerRepresentable {
    var animalJoint: AnimalPoseDetector
    func makeUIViewController(context: Context) -> some UIViewController {
        let cameraViewController = CameraViewController()
        cameraViewController.delegate = animalJoint
        return cameraViewController
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}

var isAuthorized: Bool {
    get async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        // Determine if the user previously authorized camera access.
        var isAuthorized = status == .authorized
        
        // If the system hasn't determined the user's authorization status,
        // explicitly prompt them for approval.
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        
        return isAuthorized
    }
}
