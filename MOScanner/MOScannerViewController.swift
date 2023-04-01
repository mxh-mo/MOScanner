//
//  MOScannerViewController.swift
//  MOScanner
//
//  Created by mikimo on 2023/4/1.
//
//  Add these key-values to in Info.plist to describe the request permission
//  Privacy - Camera Usage Description
//  Privacy - Photo Library Usage Description

import UIKit
import AVFoundation
import Photos
import Vision

class MOScannerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Scanner"
        
        /// check authorization when back from background
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(checkAuthorization),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        
        /// add scanView
        view.addSubview(self.scanView)
        scanView.frame = CGRect(x: 0, y: 0,
                                width: UIScreen.main.bounds.size.width,
                                height: UIScreen.main.bounds.size.height)
        
        self.addPhotosButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkAuthorization()
    }
    
    @objc func checkAuthorization() {
        MOAuthorizationManager.checkAuthorization(type: .camera) { status in
            if status != .authorized { /// haven't camera permission
                return
            }
            /// have camera permission
            self.handleAuthorized()
        }
    }
    
    // MARK: - Scan from Camera

    private func handleAuthorized() {
        DispatchQueue.main.async {
            if self.isLoadScanView { return }
            self.setupScanner()
            self.setPreview()
            self.isLoadScanView = true
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    private func setupScanner() {
        // get device
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("device error")
            return
        }
        //  get input
        let input: AVCaptureDeviceInput
        do {
          input = try AVCaptureDeviceInput(device: device)
        } catch {
          print("input error")
          return
        }
        if self.captureSession.canAddInput(input) {
            self.captureSession.addInput(input)
        } else {
            print("session can't add input")
            return
        }
        // get output
        let output = AVCaptureMetadataOutput()
        if self.captureSession.canAddOutput(output) {
            // Tips: add output must before of set output
            self.captureSession.addOutput(output)
        } else {
            print("session can't add output")
            return
        }

        // Set metadata identification type qr: QR code; Other: Barcode
        let hopeSupportTypes = [AVMetadataObject.ObjectType.qr,
                                AVMetadataObject.ObjectType.ean13,
                                AVMetadataObject.ObjectType.ean8,
                                AVMetadataObject.ObjectType.pdf417]
        var types: [AVMetadataObject.ObjectType] = []
        for type in hopeSupportTypes {
            if output.availableMetadataObjectTypes.contains(type) {
                types.append(type)
            }
        }
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = types
        //        print("support types: \(types)")
                
        output.rectOfInterest = CGRect(x: 0, y: 0,
                                       width: self.view.bounds.size.width,
                                       height: self.view.bounds.size.height)
    }
    
    private func setPreview() {
        // create preview view
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.frame = scanView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        scanView.layer.addSublayer(previewLayer)
        
        let scanBoxView = UIImageView()
        scanBoxView.image = UIImage(named: "icon_scan_box")
        scanView.addSubview(scanBoxView)
        scanBoxView.frame = CGRect(x: 0, y: 0, width: 270, height: 270)
        scanBoxView.center = scanView.center
    }
    
    private var scanView = UIView()
    private var isLoadScanView = false
    private lazy var captureSession: AVCaptureSession = {
        AVCaptureSession()
    }()
}

extension MOScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    // handle scan camera result
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first else {
            captureSession.stopRunning()
            return
        }
        guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
            print("as? AVMetadataMachineReadableCodeObject faliue")
            return
        }
        guard let stringValue = readableObject.stringValue else {
            print("stringValue faliue")
            return
        }
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        print("scan result: \(stringValue)")   // print result
        captureSession.stopRunning()
    }
    
}

// MARK: - Scan from Photos

extension MOScannerViewController {

    private func addPhotosButton() {
        let photoButton = UIButton(type: .custom)
        photoButton.setTitle("Photos", for: .normal)
        photoButton.addTarget(self, action: #selector(clickPhotos), for: .touchUpInside)
        photoButton.frame = CGRect(x: 0.0, y: 0.0, width: 60.0, height: 44.0)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: photoButton)
    }
    
    @objc private func clickPhotos() {
        MOAuthorizationManager.checkAuthorization(type: .photos) { status in
            if status != .authorized { /// haven't photos permission
                return
            }
            /// have photos permission
            DispatchQueue.main.async {
                self.openPhotoLabrary()
            }
        }
    }
    
    private func openPhotoLabrary() {
        let picker = UIImagePickerController()
        picker.title = "Photos"
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        picker.navigationBar.barStyle = .default
        self.present(picker, animated: true, completion: nil)
    }
}

extension MOScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    /// choose photo callback
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            print("choose not image")
            return
        }
        parseBarCode(image: image)
    }
    
    /// parse qrCode or barCode
    private func parseBarCode(image: UIImage) {
        guard let cgimg = image.cgImage else {
            return
        }
        
        let request = VNDetectBarcodesRequest { req, err in
            if let error = err {
                print("parseBarCode error: \(error)")
                return
            }
            self.handleResults(req.results)
        }
        
        let handler = VNImageRequestHandler(cgImage: cgimg)
        do {
            try handler.perform([request])
        } catch {
            print("parseBarCode error: \(error)")
        }
    }

    private func handleResults(_ result: [VNObservation]?) {
        guard let results = result, results.count > 0 else {
            print("parseBarCode result is nil: \(String(describing: result))")
            return
        }
        for result in results {
            self.handleResult(result)
        }
    }

    private func handleResult(_ result: VNObservation) {
        guard let barcode = result as? VNBarcodeObservation,
              let value = barcode.payloadStringValue else {
            print("handleResult covert to string error: \(result)")
            return
        }
        
        if barcode.symbology == .qr {
            print("qrcode: \(value)")
        } else {
            print("barcode: \(value), \(barcode.symbology.rawValue)")
        }
    }

}
