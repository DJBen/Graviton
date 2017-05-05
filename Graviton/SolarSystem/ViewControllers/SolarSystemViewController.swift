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

    var focusController: FocusingSupport?
    var ephemeris: Ephemeris?

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
        self.fillSolarSystemScene(scene)
        return scene
    }()

    private func fillSolarSystemScene(_ scene: SolarSystemScene) {
        scene.clear()
        let colors: [Int: UIColor] = [
            199: #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1),
            299: #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1),
            399: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1),
            499: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1),
            599: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1),
            699: #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1),
            799: #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1),
            899: #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1),
            999: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        ]
        ephemeris?.forEach { (body) in
            if let color = colors[body.naifId] {
                scene.add(body: body, color: color)
            }
        }
    }

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
        label.font = UIFont.systemFont(ofSize: 20, weight: UIFontWeightLight)
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
        cameraController = solarSystemScene
        focusController = solarSystemScene
        updateFocusedNodeLabel()
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        tapGR.require(toFail: doubleTap)
        self.view.addGestureRecognizer(tapGR)
        Horizons.shared.fetchEphemeris(mode: .mixed, update: { (ephemeris) in
            self.ephemeris = ephemeris
            self.fillSolarSystemScene(self.solarSystemScene)
        }) { (_, error) in
            if let e = error {
                print(e)
                return
            }
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.presentTransparentNavigationBar()
    }

    func handleTap(sender: UITapGestureRecognizer) {
        let scnView = self.view as! SCNView
        let p = sender.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [.boundingBoxOnly: true])
        let objectHit = hitResults.map { $0.node }.filter { $0.name != nil && $0.name!.contains("orbit") == false }
        if objectHit.count > 0 {
            let node = objectHit[0]
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
        scnView.addSubview(timeLabel)
        scnView.addConstraints(
            [
                timeLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 14),
                timeLabel.rightAnchor.constraint(equalTo: scnView.rightAnchor, constant: -16)
            ]
        )
        scnView.addSubview(warpControl)
        scnView.addConstraints(
            [
                warpControl.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 8),
                warpControl.leftAnchor.constraint(equalTo: scnView.leftAnchor, constant: 16)
            ]
        )
        scnView.addSubview(focusedObjectLabel)
        scnView.addConstraints(
            [
                focusedObjectLabel.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -16),
                focusedObjectLabel.centerXAnchor.constraint(equalTo: scnView.centerXAnchor)
            ]
        )
        scnView.delegate = self
        scnView.scene = solarSystemScene
        scnView.isPlaying = true
        scnView.antialiasingMode = .multisampling2X
        scnView.overlaySKScene = SolarSystemOverlayScene(size: scnView.frame.size)
        scnView.backgroundColor = UIColor.black
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
        let warpedJd = JulianDate(date: warpedDate).value
        self.solarSystemScene.julianDate = JulianDate(warpedJd)
        let actualTime = self.refTime.addingTimeInterval(TimeInterval(timeElapsed))
        DispatchQueue.main.async {
            self.timeLabel.text = self.dateFormatter.string(from: actualTime)
        }
        guard let focusedNode = focusController?.focusedNode, let focusedBody = self.solarSystemScene.focusedBody else {
            return
        }
        updateForFocusedNode(focusedNode, representingBody: focusedBody)
    }
}
