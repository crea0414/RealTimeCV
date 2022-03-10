//
//  SegmentationVC.swift
//  RealTimeCV
//
//  Created by 吳佳穎 on 2022/3/4.
//

import UIKit
import Vision

class SegmentationVC: UIViewController,UINavigationControllerDelegate {

    @IBOutlet weak var originImage: UIImageView!
    @IBOutlet weak var segmentationImage: UIImageView!
    let imagePicker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true

    }
    @IBAction func backPressed(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    @IBAction func selectImagePressed(_ sender: UIButton) {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
}

extension SegmentationVC: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            self.originImage.image = userPickedImage
            runVisionRequest(uiImage: userPickedImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    func runVisionRequest(uiImage inputImage: UIImage) {
        guard let model = try? VNCoreMLModel(for: DeepLab_ImageOut_scale(configuration: MLModelConfiguration()).model) else {fatalError("No model found when loading")}
            
            let request = VNCoreMLRequest(model: model, completionHandler: visionRequestDidComplete)
            request.imageCropAndScaleOption = .centerCrop
            DispatchQueue.global().async {

                let handler = VNImageRequestHandler(cgImage: inputImage.cgImage!, options: [:])
                
                do {
                    try handler.perform([request])
                }catch {
                    print(error)
                }
            }
        }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let result = request.results as? [VNPixelBufferObservation] else {fatalError("No detection result!")}
            if let pixelBuffer = result.first?.pixelBuffer {
                    self.segmentationImage.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
            }
        }
    }
    
    
}
