//
//  ARSCNViewController.swift
//  RealTimeCV
//
//  Created by 吳佳穎 on 2022/3/10.
//

import UIKit
import ARKit
import Vision
import CoreML

class ARSCNViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    var idx: UInt64 = 0
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
    
    //MARK: - ViewController related
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
//        sceneView.showsStatistics = true
//        sceneView.debugOptions =  [ARSCNDebugOptions.showFeaturePoints,
//                                   ARSCNDebugOptions.showLightInfluences
//        ]
        
    }
    @IBAction func backPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}

//MARK: - AR Related Function
extension ARSCNViewController{
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first{
            let touch_position = touch.location(in: self.sceneView)
            guard let query = sceneView.raycastQuery(from: touch_position, allowing: .estimatedPlane, alignment: .any) else {return}

            let results = sceneView.session.raycast(query)
            guard let hitTestResult = results.first else {print("No surface found"); return}
            let position = SCNVector3(x: hitTestResult.worldTransform.columns.3.x,
                                      y: hitTestResult.worldTransform.columns.3.y,
                                      z: hitTestResult.worldTransform.columns.3.z)
            print("position: \(position)")
            DispatchQueue.global(qos: .background).async {
                self.add3DObject2(inPosition: position, onThePlane: true)
            }
            

        }
    }
    
    func add3DObject(inPosition sceneVector: SCNVector3 = SCNVector3(x:0, y:0, z:-0.2), onThePlane: Bool = true){
        let airplane = SCNScene(named: "art.scnassets/ship.scn")
        if let planeNode = airplane?.rootNode.childNode(withName: "ship", recursively: true) {
            planeNode.position = sceneVector
            sceneView.scene.rootNode.addChildNode(planeNode)
        }
    }
    
    func add3DObject2(inPosition sceneVector: SCNVector3 = SCNVector3(x:0, y:0, z:-0.2), onThePlane: Bool = true){
        let airplane = SCNScene(named: "art.scnassets/Richard_Feder_memorial_plate.scn")
        if let planeNode = airplane?.rootNode.childNode(withName: "rabin_rabin_0", recursively: true) {
            print("add")
            planeNode.position = sceneVector
            sceneView.scene.rootNode.addChildNode(planeNode)
        }else{
            print("No add")
        }
    }
    
}


// MARK: - ML Related Function
extension ARSCNViewController{
    func classificationHandler(_ request: VNRequest,  error: Error?){
        guard let result = request.results as? [VNClassificationObservation] else {fatalError("Error in classification result!")}
        if let firstResult = result.first{
            DispatchQueue.main.sync {
                self.classLabel.text = firstResult.identifier
                self.confidenceLabel.text = String(format: "Confidence: %.2f", firstResult.confidence*100) + "%"
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        guard let capturedImage = self.sceneView.session.currentFrame?.capturedImage else {return}
        if idx < 1 {
            DispatchQueue.main.sync {
                print("[image size id:\(idx)] Width: \(CVPixelBufferGetWidth(capturedImage)) Height: \(CVPixelBufferGetHeight(capturedImage))")
                idx += 1
            }
        }
            let exifOrientation = exifOrientationFromDeviceOrientation()
            let visionHandler = VNImageRequestHandler.init(cvPixelBuffer: capturedImage, orientation: exifOrientation, options: [:])
            do {
                try visionHandler.perform([classificatonRequest])
            }catch{
                fatalError("Vision request error")
            }
        
    }
}

public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
    let curDeviceOrientation = UIDevice.current.orientation
    let exifOrientation: CGImagePropertyOrientation
    switch curDeviceOrientation {
    case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
        exifOrientation = .left
    case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
        exifOrientation = .up
    case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
        exifOrientation = .down
    case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
        exifOrientation = .right
    default:
        exifOrientation = .right
    }
    return exifOrientation
}
