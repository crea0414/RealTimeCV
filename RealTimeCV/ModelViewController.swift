//
//  ModelViewController.swift
//  RealTimeCV
//
//  Created by Ｃrea on 2022/2/24.
//

import UIKit
import AVFoundation
import Vision

class ModelViewController: ViewController {

    
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var DeviceOrientationLabel: UILabel!
    @IBOutlet weak var ImageOrientationLabel: UILabel!
    @IBOutlet weak var AVCaptureOrientation: UILabel!
    @IBOutlet weak var uiOrientationLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var uiImageOrientationLabel: UILabel!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var calibratedOrientationLable: UILabel!
    @IBOutlet weak var visionView: UIImageView!
    @IBOutlet weak var scaleButton: UIButton!
    
    var allRequests =  [VNCoreMLRequest]()
    var imageCropAndScaleOption: VNImageCropAndScaleOption = .centerCrop
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupModel()
        checkVNpreprocessing()
        startCaptureSession()
        print("check suported orientation: \(self.supportedInterfaceOrientations)")
    }
    @IBAction func cancelPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func scaleButtonPressed(_ sender: UIButton) {
        switch imageCropAndScaleOption {
              case .centerCrop:
                imageCropAndScaleOption = .scaleFit
              case .scaleFit:
                imageCropAndScaleOption = .scaleFill
              case .scaleFill:
                imageCropAndScaleOption = .centerCrop
              @unknown default:
                fatalError("eek!")
            }
        DispatchQueue.main.async {
            self.updateCropScaleButton()
        }
            
    }
    
    func updateCropScaleButton() {
        switch imageCropAndScaleOption {
          case .centerCrop:
            scaleButton.titleLabel?.text = "centerCrop"
          case .scaleFit:
            scaleButton.titleLabel?.text = "scaleFit"
          case .scaleFill:
            scaleButton.titleLabel?.text = "scaleFill"
          @unknown default:
            fatalError("??!")
        }
    }
    
    func setupModel(){
        // 0).Tell Core ML to use the Neural Engine if available.
        let config = MLModelConfiguration()
        config.computeUnits = .all
        // 1). load core ml model
        guard let model = try? VNCoreMLModel(for: EfficientNetB0(configuration: config).model) else {fatalError("No model found when loading")}
        // 2). make core ml request
        let singleRequest = VNCoreMLRequest(model: model) { request, error in
        guard let result = request.results as? [VNClassificationObservation] else {fatalError("No detection result!")}
            if let firstResult = result.first {
                DispatchQueue.main.sync {
                    self.classLabel.text = firstResult.identifier
                    self.confidenceLabel.text = String(format: "Confidence: %.2f", firstResult.confidence*100) + "%"
                }
            }
        }
        
        singleRequest.imageCropAndScaleOption = imageCropAndScaleOption
        self.allRequests.append(singleRequest)
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // convert sample buffer to image buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("conver sample buffer to image buffer fail!")
            return}
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let uiImage = UIImage(ciImage: ciImage)
        // rotate image by ciimage rotate function
//        let uiImage2 = UIImage(ciImage: ciImage.oriented(CGImagePropertyOrientation(getUiImageOrientationByUIDevice())))

        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Create cgImage fail")
        }
        // rotate cgImage in uiimage initializaer
        let uiImage2 = UIImage(cgImage: cgImage, scale: 1.0, orientation: getUiImageOrientationByUIDevice())
//        let uiImage2 = UIImage(cgImage: cgImage)
        
        // setup orientation
        let exifOrientation = exifOrientationFromDeviceOrientation2()
        let exifString = exifOrientationToString(orientation: exifOrientation)
        let deviceOrientationString = deviceOrientationToString(orientation: UIDevice.current.orientation)
        let avOrientation = avOrientationString(orientation: self.connection.videoOrientation)
        let uiImageOrientationString = uiImageOrientationToString(orientation: uiImage.imageOrientation)
        
        DispatchQueue.main.sync {
            if let statusBarOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation{
                let s = uiOrientationToString(orientation: statusBarOrientation)
                self.uiOrientationLabel.text = String("UI:\(s)")
            }else {
                self.uiOrientationLabel.text = String("UI:\("??")")
            }
            self.AVCaptureOrientation.text = String("AV: \(avOrientation)")
            self.DeviceOrientationLabel.text = String("Device: \(deviceOrientationString)")
            self.ImageOrientationLabel.text = String("Exif: \(exifString)")
            self.uiImageOrientationLabel.text = String("CameraFixed: \(uiImageOrientationString)")
            self.calibratedOrientationLable.text = String("Calibrated: \(uiImageOrientationToString(orientation: getUiImageOrientationByUIDevice()))")
            self.imageView.image = uiImage
            self.imageView2.image = uiImage2
//            print(String("\("?")"))
        }
        // 3). new a vision image request handler
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
//        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: exifOrientation, options: [:])
        // 4). Perform request
        for r in self.allRequests{
            r.imageCropAndScaleOption = imageCropAndScaleOption
        }
        
        do {
            try handler.perform(self.allRequests)
        }catch {
            print("detection handler error: \(error)")
        }
        
        
        
    }
    
    func exifOrientationToString(orientation:CGImagePropertyOrientation)->String{
        let result: String
        let resultWithRaw: String
        switch orientation{
        case CGImagePropertyOrientation.up:
            result = "up"
        case CGImagePropertyOrientation.upMirrored:
            result = "upMirrored"
        case CGImagePropertyOrientation.down:
            result = "down"
        case CGImagePropertyOrientation.downMirrored:
            result = "downMirrored"
        case CGImagePropertyOrientation.left:
            result = "left"
        case CGImagePropertyOrientation.leftMirrored:
            result = "leftMirrored"
        case CGImagePropertyOrientation.right:
            result = "right"
        case CGImagePropertyOrientation.rightMirrored:
            result = "rightMirrored"
        default:
            result = "unkonw default"
        }
        resultWithRaw = String("\(result): \(orientation.rawValue)")
        return resultWithRaw
    }
    
    func deviceOrientationToString(orientation:UIDeviceOrientation)->String{
        let result: String
        let resultWithRaw: String
        switch orientation{
        case UIDeviceOrientation.portrait:
            result = "portrait"
        case UIDeviceOrientation.portraitUpsideDown:
            result = "portraitUpsideDown"
        case UIDeviceOrientation.landscapeLeft:
            result = "landscapeLeft"
        case UIDeviceOrientation.landscapeRight:
            result = "landscapeRight"
        case UIDeviceOrientation.faceUp:
            result = "faceUp"
        case UIDeviceOrientation.faceDown:
            result = "faceDown"
        case UIDeviceOrientation.unknown:
            result = "unknown"
        default:
            result = "??"
        }
        resultWithRaw = String("\(result): \(orientation.rawValue)")
        return resultWithRaw
    }
    
    func uiOrientationToString(orientation:UIInterfaceOrientation)->String{
        let result: String
        let resultWithRaw: String
        switch orientation{
        case UIInterfaceOrientation.portrait:
            result = "portrait"
        case UIInterfaceOrientation.portraitUpsideDown:
            result = "portraitUpsideDown"
        case UIInterfaceOrientation.landscapeRight:
            result = "landscapeRight"
        case UIInterfaceOrientation.landscapeLeft:
            result = "landscapeLeft"
        default:
            result = "??"
        }
        resultWithRaw = String("\(result): \(orientation.rawValue)")
        return resultWithRaw
    }
    
    func uiImageOrientationToString(orientation:UIImage.Orientation)->String{
        let result: String
        let resultWithRaw: String
        switch orientation{
        case UIImage.Orientation.right:
            result = "right"
        case UIImage.Orientation.rightMirrored:
            result = "rightMirrored"
        case UIImage.Orientation.left:
            result = "left"
        case UIImage.Orientation.leftMirrored:
            result = "leftMirrored"
        case UIImage.Orientation.up:
            result = "up"
        case UIImage.Orientation.upMirrored:
            result = "upMirrored"
        case UIImage.Orientation.down:
            result = "down"
        case UIImage.Orientation.downMirrored:
            result = "downMirrored"
        default:
            result = "??"
        }
        resultWithRaw = String("\(result): \(orientation.rawValue)")
        return resultWithRaw
    }
    
    func checkVNpreprocessing(){
        // 0).Tell Core ML to use the Neural Engine if available.
        let config = MLModelConfiguration()
        config.computeUnits = .all
        // 1). load core ml model
    guard let model = try? VNCoreMLModel(for: DeepLab_ImageOut_scale(configuration: config).model) else {fatalError("No model found when loading")}
        // 2). make core ml request
        let singleRequest = VNCoreMLRequest(model: model) { request, error in
        guard let result = request.results as? [VNPixelBufferObservation] else {fatalError("No detection result!")}
            if let pixelBuffer = result.first?.pixelBuffer {
                DispatchQueue.main.sync {
                    self.visionView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
                }
            }
        }
        
        singleRequest.imageCropAndScaleOption = imageCropAndScaleOption
        self.allRequests.append(singleRequest)
    }
    
}
//extension UIInterfaceOrientation {
//    var videoOrientation: AVCaptureVideoOrientation? {
//        switch self {
//        case .portraitUpsideDown: return .portraitUpsideDown
//        case .landscapeRight: return .landscapeRight
//        case .landscapeLeft: return .landscapeLeft
//        case .portrait: return .portrait
//        default: return nil
//        }
//    }
//}


//
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
            default: self = .up
        }
    }
}
extension UIImage.Orientation {
    init(_ cgOrientation: UIImage.Orientation) {
        switch cgOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
            default: self = .up
        }
    }
}
