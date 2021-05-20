//
//  IbanNumberScannerViewController.swift
//  QR-Code
//
//  Created by Murat Celebi on 10.05.2021.
//

import UIKit
import AVFoundation
import Vision

@available(iOS 13.0, *)
class IbanNumberScannerViewController: BaseIbanNumberScannerViewController {
    var request: VNRecognizeTextRequest!
    // Temporal string tracker
    let numberTracker = StringTracker()
    var getIbanNumber: ((String) -> Void)?
        
    override func viewDidLoad() {
        request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        
        super.viewDidLoad()
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
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
