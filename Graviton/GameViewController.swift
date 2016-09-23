//
//  GameViewController.swift
//  Graviton
//
//  Created by Ben Lu on 9/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {

    var system = solarSystem
    var earth: CelestialBody {
        return system["earth"] as! CelestialBody
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/earth.scn")!
        // retrieve the ship node
        let eNode = scene.rootNode.childNode(withName: "earth", recursively: true)!
        eNode.removeFromParentNode()
        let earthNode = CelestialNode(body: CelestialBody(knownBody: .earth), geometry: eNode.geometry)
        scene.rootNode.addChildNode(earthNode)
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
//        let lookAt = SCNLookAtConstraint(target: earthNode)
//        lookAt.isGimbalLockEnabled = false
//        cameraNode.constraints = [lookAt]
        cameraNode.position = SCNVector3(x: 0, y: 0, z: geoSyncAltitude / earthEquatorialRadius + 1) + earthNode.position
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 144598667960.65134, y: 38513399986.32562, z: 0) / earthEquatorialRadius

        scene.rootNode.addChildNode(lightNode)
        
        // animate the 3d object
        let duration: CGFloat = 1200
        earthNode.runAction(SCNAction.repeatForever(SCNAction.customAction(duration: TimeInterval(duration)) { (node, elapsedTime) in
            let percentage = Float(elapsedTime / duration)
            self.system.time = earthYear * percentage
            lightNode.position = self.earth.heliocentricPosition.negated() / earthEquatorialRadius
            cameraNode.position = SCNVector3(x: 0, y: 0, z: geoSyncAltitude / earthEquatorialRadius + 1) + node.position
            print("\(elapsedTime / duration), \(self.earth.motion!.distance)")
        }))
        let rotationAxis = earthNode.rotationAxis
        earthNode.runAction(SCNAction.repeatForever(SCNAction.rotate(by: CGFloat(M_PI * 2), around: rotationAxis, duration: Double(duration / 365.0))))
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
    }
    
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            /*
            let result: AnyObject = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
            */
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
