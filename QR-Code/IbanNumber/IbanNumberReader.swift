//
//  IbanNumberReader.swift
//  QR-Code
//
//  Created by Murat Celebi on 11.05.2021.
//

import UIKit
import Vision

class IbanNumberReader {
    
    static let shared = IbanNumberReader()
    
    func recognizeNumberFrom(image: UIImage) -> String {
        guard let cgImage = image.cgImage else { return ""}
        var scannedTexts = [String]()
        var ibanNumber = ""
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                return
            }
            scannedTexts = observations.compactMap({
                $0.topCandidates(1).first?.string
            })
            
            let filtered = scannedTexts.filter({ $0.contains("TR") && $0.count > 25 })
            ibanNumber = filtered.first ?? ""
        }
        do {
            try handler.perform([request])
        }
        catch {
            print(error.localizedDescription)
        }
        return ibanNumber
    }
}
