//
//  RealityViewController.swift
//  RealTimeCV
//
//  Created by 吳佳穎 on 2022/3/11.
//

// How to run Object Capture App?
// https://developer.apple.com/forums/thread/681874?answerId=678125022#678125022

import UIKit
import ARKit
import RealityKit

class RealityViewController: UIViewController, ARSessionDelegate {
    var sceneFlag = true
    var missileFlag = false
    var mainAnchorID: UUID?
    var box: RemoteRobot2.Box?
    var idx = 0
    
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
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

    var missiel: Missile._Missile?
    @IBOutlet weak var realityView: ARView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realityView.session.delegate = self
//        realityView.debugOptions.insert(.showFeaturePoints)
//            realityView.debugOptions.insert(.showStatistics)
        if #available(iOS 13.4, *) {
//            realityView.debugOptions.insert(.showSceneUnderstanding)
        } else {
            // Fallback on earlier versions
        }
//        realityView.debugOptions.insert(.showWorldOrigin)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        realityView.session.run(<#T##ARConfiguration#>, options: <#T##ARSession.RunOptions#>)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        realityView.session.pause()
    }
    
    @IBAction func upPressed(_ sender: UIButton) {
        guard let box = self.box else {return}
        box.notifications.robotForward.post()
    }
    @IBAction func downPressed(_ sender: UIButton) {
        guard let box = self.box else {return}
        box.notifications.robotBackward.post()
    }
    @IBAction func rightPressed(_ sender: UIButton) {
        guard let box = self.box else {return}
        box.notifications.robotRight.post()
    }
    @IBAction func leftPressed(_ sender: UIButton) {
        guard let box = self.box else {return}
        box.notifications.robotLeft.post()
    }
    @IBAction func jumoPressed(_ sender: UIButton) {
        guard let box = self.box else {return}
        box.notifications.robotFly.post()
    }
    @IBAction func homePressed(_ sender: UIButton) {
        guard let box = self.box else {return}
        box.notifications.robotHome.post()
    }
    @IBAction func uturnPressed(_ sender: UIButton) {
        guard let box = self.box else {return}
        box.notifications.robotUturn.post()
    }
    
    @IBAction func firePressed(_ sender: UIButton) {
        if self.missileFlag {
            sender.tintColor = UIColor(red: 0, green: 0.0, blue: 0.0, alpha: 0.0)
        }else{
            sender.tintColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        }
        self.missileFlag = !self.missileFlag
    }
    
    
    
    
    //https://stackoverflow.com/questions/60294367/how-to-use-raycast-methods-in-realitykit
    @IBAction func tapPressed(_ sender: UITapGestureRecognizer) {
        if sceneFlag {
            
            let position = sender.location(in: realityView)
            guard let rayCast = getRayCastResult(position) else {return}

            DispatchQueue.global(qos: .background).sync {
                let anchor = AnchorEntity(world: rayCast.worldTransform)
                guard let scene = try? RemoteRobot2.loadBox() else {print("Loading Scene fial!"); return}
                self.box = scene
                anchor.addChild(self.box!)
                self.realityView.scene.anchors.append(anchor)
            }
            sceneFlag = false
        }else {
            let tapLocation = sender.location(in: realityView)
                    if let hitEntity = realityView.entity(
                        at: tapLocation
                    ) {
                        print("touched")
                        print("hitEntityName: \(hitEntity.name)")
                    }
        }
        
        if self.missileFlag{
            let position = sender.location(in: realityView)
            let results = realityView.raycast(from: position, allowing: .estimatedPlane, alignment: .any)
            guard let rayCast = results.first else {print("No surface found"); return}
            DispatchQueue.global(qos: .background).sync {
                let newAnchor = AnchorEntity(world: rayCast.worldTransform)
                guard let missiel = try? Missile.load_Missile() else {print("Loading missile fail!"); return}
                self.missiel = missiel
                newAnchor.addChild(self.missiel!)
                if self.realityView.scene.anchors.count < 2 {
                    self.realityView.scene.anchors.append(newAnchor)
                }else{
                    self.realityView.scene.anchors.remove(at: self.realityView.scene.anchors.count-1)
                    self.realityView.scene.anchors.append(newAnchor)
                }
                guard let m = self.missiel else {return}
                m.notifications.fire.post()
                
            }
            print("After add new anchor -> anchor_nums:\(self.realityView.scene.anchors.count)")
        }
        
    }
    
    private func getRayCastResult(_ position: CGPoint) -> ARRaycastResult?{
        let results = realityView.raycast(from: position, allowing: .estimatedPlane, alignment: .horizontal)
        guard let rayCast = results.first else {print("No surface found"); return nil}
        return rayCast
    }
    
    
    @IBAction func backPressed(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
}


extension RealityViewController{
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        guard let capturedImage = frame.capturedImage else {return}
        let capturedImage = frame.capturedImage
        if idx < 1 {
            DispatchQueue.main.async {
                print("[image size id:\(self.idx)] Width: \(CVPixelBufferGetWidth(capturedImage)) Height: \(CVPixelBufferGetHeight(capturedImage))")
                self.idx += 1
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
    
    func classificationHandler(_ request: VNRequest,  error: Error?){
        guard let result = request.results as? [VNClassificationObservation] else {fatalError("Error in classification result!")}
        if let firstResult = result.first{
            DispatchQueue.main.async {
                self.classLabel.text = firstResult.identifier
                self.confidenceLabel.text = String(format: "Confidence: %.2f", firstResult.confidence*100) + "%"
            }
        }
    }
}
