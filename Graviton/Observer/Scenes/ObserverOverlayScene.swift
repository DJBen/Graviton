//
//  ObserverOverlayScene.swift
//  Graviton
//
//  Created by Sihao Lu on 6/17/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SpriteKit
import Orbits
import StarryNight

class ObserverOverlayScene: SKScene {

    private lazy var timeWarpBar: TimeWarpVerticalBar = {
        let bar = TimeWarpVerticalBar()
        return bar
    }()

    private lazy var starLabel: SKLabelNode = {
        let label = SKLabelNode(text: "<Star Name>")
        label.fontName = "HelveticaNeue-Light"
        label.fontSize = 18
        label.color = Constants.TimeWarp.textColor
        label.horizontalAlignmentMode = .center
        return label
    }()

    private lazy var barBackground: SKShapeNode = {
        let rect = SKShapeNode(rect: CGRect(x: 0, y: 52, width: self.size.width, height: 40))
        rect.strokeColor = UIColor.clear
        rect.fillColor = Constants.BodyInfo.barBackgroundColor
        return rect
    }()

    private lazy var timeWarpRootNode: SKNode = SKNode()
    private lazy var starInfoRootNode: SKNode = SKNode()

    override init(size: CGSize) {
        super.init(size: size)
        setUpSceneElements()
        layoutSceneElements()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpSceneElements() {
        addChild(timeWarpRootNode)
        timeWarpRootNode.addChild(timeWarpBar)
        timeWarpRootNode.alpha = 0
        addChild(starInfoRootNode)
        starInfoRootNode.addChild(barBackground)
        starInfoRootNode.addChild(starLabel)
        starInfoRootNode.alpha = 0
    }

    private func layoutSceneElements() {
        timeWarpBar.position = CGPoint(x: size.width - 17, y: size.height / 2)
        starLabel.position = CGPoint(x: size.width / 2, y: 65)
    }

    func show(withDuration duration: TimeInterval = 0) {
        timeWarpRootNode.run(SKAction.fadeIn(withDuration: duration))
    }

    func hide(withDuration duration: TimeInterval = 0) {
        timeWarpRootNode.run(SKAction.fadeOut(withDuration: duration))
    }

    func showCelestialBodyDisplay(_ celestialBody: CelestialBody) {
        if starInfoRootNode.alpha != 1 {
            starInfoRootNode.run(SKAction.fadeIn(withDuration: 0.25))
        }
        starLabel.text = celestialBody.name
    }

    func showStarDisplay(_ star: Star) {
        if starInfoRootNode.alpha != 1 {
            starInfoRootNode.run(SKAction.fadeIn(withDuration: 0.25))
        }
        starLabel.text = String(describing: star.identity)
    }

    func hideStarDisplay() {
        starInfoRootNode.run(SKAction.fadeOut(withDuration: 0.25))
    }
}
