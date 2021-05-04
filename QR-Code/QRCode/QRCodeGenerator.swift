//
//  QRCodeGenerator.swift
//  QR-Code
//
//  Created by Murat Celebi on 4.05.2021.
//

import UIKit

class QRCodeGenerator {
    
    static let shared = QRCodeGenerator()
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    func generateQRCode(from dictionary: [String: String]) -> UIImage? {
        do {
            let data = try JSONEncoder().encode(dictionary)
            if let validData = String(data: data, encoding: .utf8) {
                print(validData)
            }
            
            if let filter = CIFilter(name: "CIQRCodeGenerator") {
                filter.setValue(data, forKey: "inputMessage")
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                
                if let output = filter.outputImage?.transformed(by: transform) {
                    return UIImage(ciImage: output)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
}
