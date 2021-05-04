//
//  ViewController.swift
//  QR-Code
//
//  Created by Murat Celebi on 29.04.2021.
//

import UIKit
import TinyConstraints
import AVFoundation

class HomeViewController: UIViewController {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let scanButton: UIButton = {
        let button = UIButton()
        button.setTitle("ScanQR", for: .normal)
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
        view.addSubview(imageView)
        imageView.centerInSuperview()
        imageView.size(.init(width: 300, height: 300))
        imageView.image = QRCodeGenerator.shared.generateQRCode(from: "Murat Celebi")
        
        view.addSubview(scanButton)
        scanButton.topToBottom(of: imageView).constant = 20
        scanButton.centerXToSuperview()
        scanButton.size(.init(width: 100, height: 50))
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        
        view.addSubview(scanTextLabel)
        scanTextLabel.topToBottom(of: scanButton).constant = 20
        scanTextLabel.centerXToSuperview()
    }

    @IBAction private func scanButtonTapped() {
        let viewController = QRCodeScannerViewController(qrDataType: .string)
        present(viewController, animated: true, completion: nil)
        viewController.getStringData = { [weak self] string in
            self?.scanTextLabel.text = string
        }
    }
    
}
