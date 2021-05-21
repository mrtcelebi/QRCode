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
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        return stack
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
        label.numberOfLines = 0
        return label
    }()
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureContents()
    }
    
    private func configureContents() {
        view.backgroundColor = .white
        view.addSubview(scanTextLabel)
        scanTextLabel.edgesToSuperview(excluding: .bottom, insets: UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0), usingSafeArea: true)
                
        view.addSubview(imageView)
        imageView.topToBottom(of: scanTextLabel).constant = 50
        imageView.centerXToSuperview()
        imageView.size(.init(width: 300, height: 300))
        imageView.image = QRCodeGenerator.shared.generateQRCode(from: "Murat Celebi")
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
        imageView.addGestureRecognizer(tapGesture)
        
        view.addSubview(stackView)
        stackView.topToBottom(of: imageView).constant = 50
        stackView.edgesToSuperview(excluding: [.top, .bottom], insets: UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 50))
        stackView.addArrangedSubview(scanButton)
        stackView.addArrangedSubview(saveImageButton)
        stackView.addArrangedSubview(scanIbanNumberButton)
        scanButton.height(40)
        saveImageButton.height(40)
        scanIbanNumberButton.height(40)
        
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        saveImageButton.addTarget(self, action: #selector(saveImageButtonTapped), for: .touchUpInside)
        if #available(iOS 13.0, *) {
            scanIbanNumberButton.addTarget(self, action: #selector(scanIbanNumberButtonTapped), for: .touchUpInside)
        }
    }

    @IBAction private func scanButtonTapped() {
        let viewController = QRCodeScannerViewController(qrDataType: .string)
        present(viewController, animated: true, completion: nil)
        viewController.getStringData = { [weak self] string in
            DispatchQueue.main.async {
                self?.scanTextLabel.text = string
            }
        }
        viewController.getQrCodeString = { [weak self] qrCodeString in
            DispatchQueue.main.async {
                self?.scanTextLabel.text = qrCodeString
            }
            self?.dismiss(animated: true)
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
    
    @available(iOS 13.0, *)
    @IBAction private func scanIbanNumberButtonTapped() {
        let viewController = IbanNumberScannerViewController()
        present(viewController, animated: true, completion: nil)
        viewController.getIbanNumber = { [weak self] iban in
            DispatchQueue.main.async {
                self?.scanTextLabel.text = iban
            }
        }
    }
    
    @IBAction private func imageViewTapped() {
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
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

extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let originalImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        guard let cgImage = originalImage.cgImage else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        if #available(iOS 13.0, *) {
            IbanNumberReader.shared.performVisionRequest(image: cgImage, orientation: .up, handleIbanNumber: { [weak self] ibanNumber in
                DispatchQueue.main.async {
                    self?.scanTextLabel.text = ibanNumber
                }
            })
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}
