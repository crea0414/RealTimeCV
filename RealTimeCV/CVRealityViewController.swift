//
//  CVRealityViewController.swift
//  RealTimeCV
//
//  Created by 吳佳穎 on 2022/3/17.
//

import UIKit
import ARKit
import RealityKit
import Vision

class CVRealityViewController: UIViewController {
    
    @IBOutlet weak var arView: ARView!
    @IBOutlet weak var classLable: UILabel!
    @IBOutlet weak var confidenceLable: UILabel!
    
    let coachingOverlay = ARCoachingOverlayView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView.session.delegate = self
//        arView.debugOptions.insert(.showAnchorGeometry)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
    
    @IBAction func backPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func tapPressed(_ sender: UITapGestureRecognizer) {
        let position = sender.location(in: arView)
        let results = arView.raycast(from: position, allowing: .estimatedPlane, alignment: .horizontal)
        guard let rayCast = results.first else {print("No surface found"); return}
        
        DispatchQueue.global(qos: .background).sync {
            let newAnchor = AnchorEntity(world: rayCast.worldTransform)
            guard let classLabelText = self.classLable.text else {print("No Label!"); return}
            let textMesh = MeshResource.generateText(classLabelText,
                                          extrusionDepth: 0.001,
                                          font: .systemFont(ofSize: 0.03),
                                          containerFrame: CGRect.zero,
                                          alignment: .center,
                                          lineBreakMode: .byCharWrapping
                )
            let textEntity = ModelEntity(mesh: textMesh, materials: [UnlitMaterial(color: UIColor.orange)])
                                         
            newAnchor.addChild(textEntity)
            arView.scene.anchors.append(newAnchor)
            
        }
    }
    
    
    //MARK: -  Setup Vision Request
    lazy var classificatonRequest: VNCoreMLRequest = {
        do {
            /// step1 load mlmodel
            let model = try VNCoreMLModel(for: EfficientNetB0.init(configuration: MLModelConfiguration()).model)
            /// step2 create vn request and return
            let request = VNCoreMLRequest.init(model: model, completionHandler: classificationHandler)
            request.imageCropAndScaleOption = .centerCrop
            return request
        }catch{
            fatalError("Initial classification request fail")
        }
    }()

}

extension CVRealityViewController: ARSessionDelegate{
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        guard let capturedImage = frame.capturedImage else {return}
        let capturedImage = frame.capturedImage
            let exifOrientation = exifOrientationFromDeviceOrientation()
            let visionHandler = VNImageRequestHandler.init(cvPixelBuffer: capturedImage, orientation: exifOrientation, options: [:])
            do {
                try visionHandler.perform([classificatonRequest])
            }catch{
                fatalError("Vision request error")
            }
    }
    
    func classificationHandler(_ request: VNRequest,  error: Error?){
        guard let result = request.results as? [VNClassificationObservation] else {fatalError("Error in classification result!")}
        if let firstResult = result.first{
            DispatchQueue.main.async {
                self.classLable.text = firstResult.identifier
                self.confidenceLable.text = String(format: "Confidence: %.2f", firstResult.confidence*100) + "%"
                if firstResult.confidence >= 0.5{
                    self.classLable.textColor = UIColor.green
                    self.confidenceLable.textColor = UIColor.green
                }else{
                    self.classLable.textColor = UIColor.white
                    self.confidenceLable.textColor = UIColor.white
                }
            }
        }
    }
}

