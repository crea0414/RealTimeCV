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

class RealityViewController: UIViewController {
    var sceneFlag = true
    var mainAnchorID: UUID?
    var box: RemoteRobot2.Box?
    @IBOutlet weak var realityView: ARView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        realityView.debugOptions.insert(.showFeaturePoints)
        if #available(iOS 13.4, *) {
//            realityView.debugOptions.insert(.showSceneUnderstanding)
        } else {
            // Fallback on earlier versions
        }
//        realityView.debugOptions.insert(.showWorldOrigin)
        
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
    
    
    
    
    
    //https://stackoverflow.com/questions/60294367/how-to-use-raycast-methods-in-realitykit
    @IBAction func tapPressed(_ sender: UITapGestureRecognizer) {
        if sceneFlag {
            
            let position = sender.location(in: realityView)
//            guard let query = realityView.makeRaycastQuery(from: position, allowing: .estimatedPlane, alignment: .any)else {return}
//            let results = realityView.session.raycast(query)
            let results = realityView.raycast(from: position, allowing: .estimatedPlane, alignment: .horizontal)
            guard let rayCast = results.first else {print("No surface found"); return}
            DispatchQueue.global(qos: .background).sync {
                let anchor = AnchorEntity(world: rayCast.worldTransform)
                guard let scene = try? RemoteRobot2.loadBox() else {print("Loading Scene fial!"); return}
//                guard let scene = try?  MyScene.loadBox() else {print("Loading Scene fial!"); return}

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
                        // touched !

//                        return ;
                    }
        }
        
    }
    
    
    
    @IBAction func backPressed(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
}
