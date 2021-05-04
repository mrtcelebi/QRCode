//
//  QRCodeReaderViewController.swift
//  QR-Code
//
//  Created by Murat Celebi on 29.04.2021.
//

import AVFoundation
import UIKit

class QRCodeScannerViewController: UIViewController {
    
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "ic_close")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .black
        return button
    }()
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: ScannerOverlayPreviewLayer!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    var getDictionaryData: (([String: String]) -> Void)?
    var getStringData: ((String) -> Void)?
    
    enum QRDataType {
        case string
        case dictionary
    }
    
    let qrDataType: QRDataType
    
    init(qrDataType: QRDataType) {
        self.qrDataType = qrDataType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureContents()
        scanQR()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkCameraPermission()
    }
    
    private func configureContents() {
        view.backgroundColor = .white
        
        view.addSubview(dismissButton)
        dismissButton.topToSuperview().constant = 25
        dismissButton.leadingToSuperview().constant = 25
        dismissButton.size(.init(width: 20, height: 20))
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
    }
    
    private func scanQR() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = ScannerOverlayPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.backgroundColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        previewLayer.maskSize = .init(width: 250, height: 250)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        view.bringSubviewToFront(dismissButton)
        
        captureSession.startRunning()
    }
    
    private func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if !granted {
                    self?.showOpenSettingsAlert()
                }
            }
        case .denied, .restricted:
            showOpenSettingsAlert()
        default:
            return
        }
    }
    
    private func showOpenSettingsAlert() {
        let alertController = UIAlertController (title: nil, message: "Go to Settings?", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)")
                })
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction private func dismissButtonTapped() {
        dismiss(animated: true)
    }
}

extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            if metadataObject.type == .qr {
                let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject
                do {
                    switch qrDataType {
                    case .string:
                        guard let stringValue = readableObject?.stringValue else { return }
                        //do stuff with string
                        getStringData?(stringValue)
                        print(stringValue)
                    case .dictionary:
                        if let validData = readableObject?.stringValue?.data(using: .utf8) {
                            let dict = try JSONDecoder().decode([String: String].self, from: validData)
                            //do stuff with dict
                            getDictionaryData?(dict)
                            print(dict.values)
                        }
                    }
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        dismiss(animated: true)
    }
}
