//
//  SolarSystemViewController.swift
//  Graviton
//
//  Created by Ben Lu on 9/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit
import SpriteKit
import SceneKit
import Orbits
import SpaceTime
import MathUtil

class SolarSystemViewController: SceneController {

    static let focusDistanceThreshold: CGFloat = 30

    var focusController: FocusingSupport?

    var lastRenderTime: TimeInterval!
    var timeElapsed: TimeInterval = 0
    var refTime: Date!

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    lazy var solarSystemScene: SolarSystemScene = {
        let scene = SolarSystemScene()
        return scene
    }()

    private var ephemerisSubscriptionId: SubscriptionUUID!

    private var scnView: SCNView {
        return self.view as! SCNView
    }

    private var sol2dScene: SolarSystemOverlayScene {
        return self.scnView.overlaySKScene as! SolarSystemOverlayScene
    }

    lazy var timeLabel: UILabel = {
        return self.defaultLabel()
    }()

    lazy var warpControl: WarpControl = {
        let control = WarpControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    lazy var focusedObjectLabel: UILabel = {
        let label = self.defaultLabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.light)
        return label
    }()

    var velocityLabel: SKLabelNode {
        return self.sol2dScene.velocityLabel
    }

    var distanceLabel: SKLabelNode {
        return self.sol2dScene.distanceLabel
    }

    private func defaultLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func updateFocusedNodeLabel() {
        if let naifId = focusController?.focusedNode?.name {
            if let name = NaifCatalog.name(forNaif: Int(naifId)!) {
                focusedObjectLabel.text = name
            } else {
                focusedObjectLabel.text = solarSystemScene.focusedBody?.name
            }
        } else {
            focusedObjectLabel.text = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
        refTime = Date()
        cameraModifier = solarSystemScene
        focusController = solarSystemScene
        updateFocusedNodeLabel()
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        tapGR.require(toFail: doubleTap)
        self.view.addGestureRecognizer(tapGR)
        ephemerisSubscriptionId = EphemerisManager.default.subscribe(mode: .realtime, didLoad: solarSystemScene.ephemerisDidLoad(ephemeris:), didUpdate: solarSystemScene.ephemerisDidUpdate(ephemeris:))
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return Device.isiPhoneX == false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        let scnView = self.view as! SCNView
        let point = sender.location(in: view)
        let distances = solarSystemScene.spheres.childNodes.map { (sphere) -> (SCNNode, CGFloat) in
            let screenPoint = CGPoint(scnView.projectPoint(sphere.position))
            return (sphere, point.distance(toPoint: screenPoint))
        }.sorted { $0.1 < $1.1 }.filter { $0.1 < SolarSystemViewController.focusDistanceThreshold }

        if let (node, _) = distances.first {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.25
            focusController?.focus(atNode: node)
            SCNTransaction.commit()
            updateFocusedNodeLabel()
        }
    }

    private func setupViewElements() {
        let scnView = self.view as! SCNView
        navigationController?.navigationBar.tintColor = Constants.Menu.tintColor
        navigationItem.titleView = timeLabel
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: warpControl)
        scnView.addSubview(focusedObjectLabel)
        scnView.addConstraints(
            [
                focusedObjectLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                focusedObjectLabel.centerXAnchor.constraint(equalTo: scnView.centerXAnchor)
            ]
        )
        scnView.delegate = self
        scnView.scene = solarSystemScene
        scnView.isPlaying = true
        scnView.antialiasingMode = .none
        scnView.overlaySKScene = SolarSystemOverlayScene(size: scnView.frame.size)
        scnView.backgroundColor = UIColor.black
        cameraController?.cameraNode = solarSystemScene.cameraNode
    }

    private func updateForFocusedNode(_ focusedNode: SCNNode, representingBody focusedBody: Body) {
        self.velocityLabel.isHidden = self.focusedObjectLabel.text == "Sun"
        self.distanceLabel.isHidden = self.focusedObjectLabel.text == "Sun"
        self.velocityLabel.text = focusedBody.velocityString
        self.distanceLabel.text = focusedBody.distanceString
        self.velocityLabel.alpha = focusedNode.opacity
        self.distanceLabel.alpha = focusedNode.opacity

        let overlayPosition = scnView.project3dTo2d(focusedNode.position).point
        let nodeSize = scnView.projectedSize(of: focusedNode) * CGFloat(focusedNode.scale.x)
        let nodeHeight = nodeSize.height
        let newCenter = overlayPosition - CGVector(dx: 0, dy: velocityLabel.frame.size.height / 2 + nodeHeight)

        self.distanceLabel.position = newCenter
        self.velocityLabel.position = newCenter - CGVector(dx: 0, dy: distanceLabel.frame.size.height)
    }

    private func updateAnnotations() {

    }

    // MARK: - Scene Renderer Delegate

    override func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        super.renderer(renderer, didRenderScene: scene, atTime: time)
        if lastRenderTime == nil {
            lastRenderTime = time
        }
        let dt: TimeInterval = time - lastRenderTime
        lastRenderTime = time
        let warpedDeltaTime = dt * warpControl.speed.multiplier
        timeElapsed += warpedDeltaTime
        let warpedDate = Date(timeInterval: timeElapsed, since: refTime)
        let warpedJd = JulianDay(date: warpedDate).value
        self.solarSystemScene.julianDay = JulianDay(warpedJd)
        let actualTime = self.refTime.addingTimeInterval(TimeInterval(timeElapsed))
        guard let focusedNode = focusController?.focusedNode, let focusedBody = self.solarSystemScene.focusedBody else {
            return
        }
        DispatchQueue.main.async {
            self.timeLabel.text = self.dateFormatter.string(from: actualTime)
            self.updateForFocusedNode(focusedNode, representingBody: focusedBody)
        }
    }
}
