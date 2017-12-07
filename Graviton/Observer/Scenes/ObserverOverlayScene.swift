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

    private lazy var barBackground: SKShapeNode = {
        let rect = SKShapeNode(rect: CGRect(x: 0, y: 52, width: self.size.width, height: 40))
        rect.strokeColor = UIColor.clear
        rect.fillColor = Constants.BodyInfo.barBackgroundColor
        return rect
    }()

    var isShowingStarLabel: Bool {
        return starInfoRootNode.alpha != 0
    }

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
        starInfoRootNode.alpha = 0
    }

    private func layoutSceneElements() {
        timeWarpBar.position = CGPoint(x: size.width - 17, y: size.height / 2)
    }

    func show(withDuration duration: TimeInterval = 0) {
        timeWarpRootNode.run(SKAction.fadeIn(withDuration: duration))
    }

    func hide(withDuration duration: TimeInterval = 0) {
        timeWarpRootNode.run(SKAction.fadeOut(withDuration: duration))
    }
}
