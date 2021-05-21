//
//  BaseIbanNumberScannerViewController.swift
//  QR-Code
//
//  Created by Murat Celebi on 10.05.2021.
//

import UIKit
import AVFoundation
import Vision

@available(iOS 13.0, *)
class IbanNumberScannerViewController: UIViewController {
    
    var request: VNRecognizeTextRequest!
    
    // UI objects
    let previewView = IbanNumberScannerPreviewView()
    
    // Temporal string tracker
    let numberTracker = StringTracker()
    var getIbanNumber: ((String) -> Void)?
    
    private let cutoutView = UIView()
    private var maskLayer = CAShapeLayer()
    
    // Capture related objects
    private let captureSession = AVCaptureSession()
    private let captureSessionQueue = DispatchQueue(label: "CaptureSessionQueue")
    
    private var captureDevice: AVCaptureDevice?
    
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
    
    // Region of interest (ROI) and text orientation
    var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    var textOrientation = CGImagePropertyOrientation.up
    
    // Coordinate transforms
    private var bufferAspectRatio: Double!
    // Transform from UI orientation to buffer orientation.
    private var uiRotationTransform = CGAffineTransform.identity
    // Transform bottom-left coordinates to top-left.
    private var bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
    // Transform coordinates in ROI to global coordinates (still normalized).
    private var roiToGlobalTransform = CGAffineTransform.identity
    
    // Vision -> AVF coordinate transform.
    var visionToAVFTransform = CGAffineTransform.identity
    
// MARK: - ViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        configureContents()
        
        captureSessionQueue.async {
            self.setupCamera()
            
            DispatchQueue.main.async {
                self.calculateRegionOfInterest()
            }
        }
    }
    
    private func configureContents() {
        view.addSubview(previewView)
        previewView.edgesToSuperview()
        previewView.session = captureSession
        
        view.addSubview(cutoutView)
        cutoutView.edgesToSuperview()
        cutoutView.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.fillRule = .evenOdd
        cutoutView.layer.mask = maskLayer
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCutout()
    }
    
// MARK: - Setup
    private func calculateRegionOfInterest() {
        let desiredHeightRatio = 0.15
        let desiredWidthRatio = 0.6
        let maxPortraitWidth = 0.8
        
        let size = CGSize(width: min(desiredWidthRatio * bufferAspectRatio, maxPortraitWidth), height: desiredHeightRatio / bufferAspectRatio)
        
        regionOfInterest.origin = CGPoint(x: (1 - size.width) / 2, y: (1 - size.height) / 2)
        regionOfInterest.size = size
        
        DispatchQueue.main.async {
            self.updateCutout()
        }
    }
    
    private func updateCutout() {
        textOrientation = CGImagePropertyOrientation.right
        uiRotationTransform = CGAffineTransform(translationX: 0, y: 1).rotated(by: -CGFloat.pi / 2)
        
        let roi = regionOfInterest
        roiToGlobalTransform = CGAffineTransform(translationX: roi.origin.x, y: roi.origin.y).scaledBy(x: roi.width, y: roi.height)
        
        visionToAVFTransform = roiToGlobalTransform.concatenating(bottomToTopTransform).concatenating(uiRotationTransform)
        
        let roiRectTransform = bottomToTopTransform.concatenating(uiRotationTransform)
        let cutout = previewView.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: regionOfInterest.applying(roiRectTransform))
        
        // Create the mask.
        let path = UIBezierPath(rect: cutoutView.frame)
        path.append(UIBezierPath(roundedRect: cutout, cornerRadius: 10))
        maskLayer.path = path.cgPath
    }
    
    private func setupCamera() {
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else {
            print("Could not create capture device.")
            return
        }
        self.captureDevice = captureDevice
        
        if captureDevice.supportsSessionPreset(.hd4K3840x2160) {
            captureSession.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
            bufferAspectRatio = 3840.0 / 2160.0
        } else {
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
            bufferAspectRatio = 1920.0 / 1080.0
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Could not create device input.")
            return
        }
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
        
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            videoDataOutput.connection(with: AVMediaType.video)?.preferredVideoStabilizationMode = .off
        } else {
            print("Could not add VDO output")
            return
        }
        
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.videoZoomFactor = 2
            captureDevice.autoFocusRangeRestriction = .near
            captureDevice.unlockForConfiguration()
        } catch {
            print("Could not set zoom level due to error: \(error)")
            return
        }
        
        captureSession.startRunning()
    }
    
    func stopRunning() {
        captureSessionQueue.sync {
            self.captureSession.stopRunning()
        }
    }
    
// MARK: - Text recognition
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        var numbers = [String]()
        
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        let maximumCandidates = 1
        
        for visionResult in results {
            guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
            
            
            if let result = candidate.string.extractIbanNumber() {
                let (_, number) = result
                numbers.append(number)
            }
        }
        
        numberTracker.logFrame(strings: numbers)
        
        if let sureNumber = numberTracker.getStableString() {
            stopRunning()
            numberTracker.reset(string: sureNumber)
            getIbanNumber?(sureNumber)
            DispatchQueue.main.async { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
@available(iOS 13.0, *)
extension IbanNumberScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = false
            request.regionOfInterest = regionOfInterest
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                print(error)
            }
        }
    }
    
}
