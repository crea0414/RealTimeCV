//
//  FullScreenViewController.swift
//  RealTimeCV
//
//  Created by 吳佳穎 on 2022/2/26.
//

import UIKit
import Vision
import AVFoundation

class FullScreenViewController: ViewController {
    
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    var allRequests =  [VNImageBasedRequest]()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupModel()
        startCaptureSession()
    }
    @IBAction func cancelPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
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
        
        singleRequest.imageCropAndScaleOption = .centerCrop
        self.allRequests = [singleRequest]
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // convert sample buffer to image buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("conver sample buffer to image buffer fail!")
            return}
        // setup orientation
        let exifOrientation = exifOrientationFromDeviceOrientation2()
        // 3). new a vision image request handler
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
//        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: exifOrientation, options: [:])
        // 4). Perform request
        do {
            try handler.perform(self.allRequests)
        }catch {
            print("detection handler error: \(error)")
        }
    }
    
    
}
