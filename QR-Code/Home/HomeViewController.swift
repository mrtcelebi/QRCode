//
//  ViewController.swift
//  QR-Code
//
//  Created by Murat Celebi on 29.04.2021.
//

import UIKit
import TinyConstraints
import AVFoundation
import Photos

class HomeViewController: UIViewController {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let scanButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("ScanQR", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .red
        return button
    }()
    
    private let saveImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Image", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .blue
        return button
    }()
    
    private let scanIbanNumberButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Scan Iban", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .red
        return button
    }()
    
    private let scanTextLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureContents()
    }
    
    private func configureContents() {
        view.addSubview(scanTextLabel)
        scanTextLabel.edgesToSuperview(excluding: .bottom, insets: UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0), usingSafeArea: true)
                
        view.addSubview(imageView)
        imageView.centerInSuperview()
        imageView.size(.init(width: 300, height: 300))
        imageView.image = QRCodeGenerator.shared.generateQRCode(from: "Murat Celebi")
        
        view.addSubview(scanButton)
        scanButton.topToBottom(of: imageView).constant = 20
        scanButton.centerXToSuperview()
        scanButton.size(.init(width: 200, height: 50))
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        
        view.addSubview(saveImageButton)
        saveImageButton.topToBottom(of: scanButton).constant = 20
        saveImageButton.centerXToSuperview()
        saveImageButton.size(.init(width: 200, height: 50))
        saveImageButton.addTarget(self, action: #selector(saveImageButtonTapped), for: .touchUpInside)
        
        view.addSubview(scanIbanNumberButton)
        scanIbanNumberButton.topToBottom(of: saveImageButton).constant = 20
        scanIbanNumberButton.centerXToSuperview()
        scanIbanNumberButton.size(.init(width: 200, height: 50))
        scanIbanNumberButton.addTarget(self, action: #selector(scanIbanNumberButtonTapped), for: .touchUpInside)
    }

    @IBAction private func scanButtonTapped() {
        let viewController = QRCodeScannerViewController(qrDataType: .string)
        present(viewController, animated: true, completion: nil)
        viewController.getStringData = { [weak self] string in
            DispatchQueue.main.async {
                self?.scanTextLabel.text = string
            }
        }
    }
    
    @IBAction private func saveImageButtonTapped() {
        screenShot()
    }

    private func screenShot() {
        let layer = UIApplication.shared.keyWindow!.layer
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        UIImageWriteToSavedPhotosAlbum(screenshot!, nil, nil, nil)
    }
    
    @IBAction private func scanIbanNumberButtonTapped() {
        let viewController = IbanNumberScannerViewController()
        present(viewController, animated: true, completion: nil)
        viewController.getIbanNumber = { [weak self] iban in
            DispatchQueue.main.async {
                self?.scanTextLabel.text = iban
            }
        }
    }
    
//    func checkPhotoLibraryPermission() {
//        let status = PHPhotoLibrary.authorizationStatus()
//        switch status {
//        case .authorized:
//        print("authorized")
//        case .denied, .restricted :
//        //handle denied status
//        case .notDetermined:
//            // ask for permissions
//            PHPhotoLibrary.requestAuthorization { status in
//                switch status {
//                case .authorized:
//                // as above
//                case .denied, .restricted:
//                // as above
//                case .notDetermined:
//                // won't happen but still
//                }
//            }
//        }
//    }
}
