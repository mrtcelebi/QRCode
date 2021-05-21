//
//  IbanNumberScannerPreviewView.swift
//  QR-Code
//
//  Created by Murat Celebi on 10.05.2021.
//

import UIKit
import AVFoundation

class IbanNumberScannerPreviewView: UIView {
	var videoPreviewLayer: AVCaptureVideoPreviewLayer {
		guard let layer = layer as? AVCaptureVideoPreviewLayer else {
			fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
		}
		
		return layer
	}
	
	var session: AVCaptureSession? {
		get {
			return videoPreviewLayer.session
		}
		set {
			videoPreviewLayer.session = newValue
		}
	}
    
	override class var layerClass: AnyClass {
		return AVCaptureVideoPreviewLayer.self
	}
}
