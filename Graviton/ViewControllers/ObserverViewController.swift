//
//  ObserverViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 1/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit
import Orbits

class ObserverViewController: SceneController, SKSceneDelegate {
    
    private lazy var obsScene = ObserverScene()
    private var scnView: SCNView {
        return self.view as! SCNView
    }
    private lazy var flatStarScene: StarScene = {
        return StarScene(size: self.scnView.frame.size)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
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
    
    private func setupViewElements() {
        scnView.delegate = self
        scnView.scene = obsScene
        cameraController = obsScene
        scnView.isPlaying = true
        scnView.overlaySKScene = flatStarScene
        flatStarScene.delegate = self
        scnView.backgroundColor = UIColor.black
        viewSlideDivisor = 10000
        viewSlideVelocityCap = 300
        cameraInversion = [.invertX, .invertY]
    }
    
    private var starPos = [(DistantStar, CGPoint)]()
    private func updateStarsInFrustrum() {
        let visibleNodes = obsScene.rootNode.childNodes { (child, _) -> Bool in
            if child.name == nil { return false }
            let projected = self.scnView.projectPoint(child.position)
            return self.scnView.frame.contains(CGPoint(x: CGFloat(projected.x), y: CGFloat(projected.y)))
        }
        starPos = visibleNodes.flatMap { (node) -> (DistantStar, CGPoint)? in
            if let name = node.name, let numId = Int(name), let star = DistantStar.id(numId) {
                let coord = self.scnView.project3dTo2d(node.position)
                return (star, coord)
            }
            return nil
        }
    }
    
    // MARK: - Scene Renderer Delegate
    
    override func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        super.renderer(renderer, didRenderScene: scene, atTime: time)
//        updateStarsInFrustrum()
    }
    
    // MARK: - SKScene Delegate
    func update(_ currentTime: TimeInterval, for scene: SKScene) {
//        flatStarScene.drawStars(starPos)
    }
}
