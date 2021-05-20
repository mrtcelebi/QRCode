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
    var boxLayer = [CAShapeLayer]()
    var getIbanNumber: ((String) -> Void)?
    
    typealias ColoredBoxGroup = (color: CGColor, boxes: [CGRect])
    
    override func viewDidLoad() {
        request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        
        super.viewDidLoad()
    }
    
    // MARK: - Text recognition
    
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        var numbers = [String]()
        var redBoxes = [CGRect]()
        var greenBoxes = [CGRect]()
        
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        let maximumCandidates = 1
        
        for visionResult in results {
            guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
            
            var numberIsSubstring = true
            
            if let result = candidate.string.extractIbanNumber() {
                let (range, number) = result
                
                if let box = try? candidate.boundingBox(for: range)?.boundingBox {
                    numbers.append(number)
                    greenBoxes.append(box)
                    numberIsSubstring = !(range.lowerBound == candidate.string.startIndex && range.upperBound == candidate.string.endIndex)
                }
            }
            if numberIsSubstring {
                redBoxes.append(visionResult.boundingBox)
            }
        }
        
        numberTracker.logFrame(strings: numbers)
        show(boxGroups: [(color: UIColor.red.cgColor, boxes: redBoxes), (color: UIColor.green.cgColor, boxes: greenBoxes)])
        
        if let sureNumber = numberTracker.getStableString() {
            showString(string: sureNumber)
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
    
    // MARK: - Bounding box drawing
    
    private func draw(rect: CGRect, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 0.5
        layer.borderColor = color
        layer.borderWidth = 1
        layer.frame = rect
        boxLayer.append(layer)
        previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
    }
    
    private func removeBoxes() {
        for layer in boxLayer {
            layer.removeFromSuperlayer()
        }
        boxLayer.removeAll()
    }
    
    private func show(boxGroups: [ColoredBoxGroup]) {
        DispatchQueue.main.async {
            let layer = self.previewView.videoPreviewLayer
            self.removeBoxes()
            for boxGroup in boxGroups {
                let color = boxGroup.color
                for box in boxGroup.boxes {
                    let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
                    self.draw(rect: rect, color: color)
                }
            }
        }
    }
}
