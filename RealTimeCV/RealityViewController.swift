//
//  RealityViewController.swift
//  RealTimeCV
//
//  Created by 吳佳穎 on 2022/3/11.
//

import UIKit
import RealityKit

class RealityViewController: UIViewController {

    @IBOutlet weak var realityView: ARView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func backPressed(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
}
