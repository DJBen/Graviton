//
//  ObserverOverlayScene.swift
//  Graviton
//
//  Created by Sihao Lu on 6/17/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SpriteKit

class ObserverOverlayScene: SKScene {

    private lazy var timeWarpLabel: SKLabelNode = {
        let label = SKLabelNode(text: "Time Warp Engaged")
        label.fontName = "HelveticaNeue-Light"
        label.fontSize = 16
        label.color = Constants.TimeWarp.textColor
        label.horizontalAlignmentMode = .center
        return label
    }()

    private lazy var timeWarpBar: TimeWarpVerticalBar = {
        let bar = TimeWarpVerticalBar()
        return bar
    }()

    private lazy var rootNode: SKNode = SKNode()

    override init(size: CGSize) {
        super.init(size: size)
        setUpSceneElements()
        layoutSceneElements()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpSceneElements() {
        addChild(rootNode)
        rootNode.addChild(timeWarpLabel)
        rootNode.addChild(timeWarpBar)
        rootNode.alpha = 0
    }

    private func layoutSceneElements() {
        timeWarpLabel.position = CGPoint(x: size.width / 2, y: -size.height - 100)
        timeWarpBar.position = CGPoint(x: size.width - 17, y: size.height / 2)
    }

    func show(withDuration duration: TimeInterval = 0) {
        rootNode.run(SKAction.fadeIn(withDuration: duration))
    }

    func hide(withDuration duration: TimeInterval = 0) {
        rootNode.run(SKAction.fadeOut(withDuration: duration))
    }
}
