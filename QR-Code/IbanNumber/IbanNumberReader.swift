//
//  IbanNumberReader.swift
//  QR-Code
//
//  Created by Murat Celebi on 11.05.2021.
//

import UIKit
import Vision

@available(iOS 13.0, *)
class IbanNumberReader {
    
    static let shared = IbanNumberReader()
    
    func performVisionRequest(image: CGImage, orientation: CGImagePropertyOrientation, handleIbanNumber: @escaping ((String) -> ())) {
        
        let requests = createVisionRequests { (scannedTexts) in
            let filtered = scannedTexts.filter({ $0.isValidIbanNumber() })
            guard !filtered.isEmpty else {
                print("Error")
                return
            }
            let ibanNumber = filtered.first!
            handleIbanNumber(ibanNumber)
        }
        
        let imageRequestHandler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])
        
        do {
            try imageRequestHandler.perform(requests)
        } catch let error as NSError {
            print("Failed to perform image request: \(error)")
            return
        }
    }
    
    private func createVisionRequests(didHandle: @escaping([String]) -> ()) -> [VNRequest] {
        var requests: [VNRequest] = []
        var scannedTexts = [String]()
        
        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    scannedTexts = requestResults.compactMap({
                        $0.topCandidates(1).first?.string
                    })
                    didHandle(scannedTexts)
                } else {
                    // Show Error
                }
            } else {
                // Show Error
            }
        })
        
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = false
        
        requests.append(textRecognitionRequest)
        
        return requests
    }
}
