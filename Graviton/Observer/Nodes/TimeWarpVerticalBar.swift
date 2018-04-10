//
//  TimeWarpVerticalBar.swift
//  Graviton
//
//  Created by Sihao Lu on 6/17/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SpriteKit
import MathUtil

class TimeWarpVerticalBar: SKNode {
    private lazy var barNode: SKShapeNode = {
        let shapeNode = SKShapeNode(rect: CGRect(origin: CGPoint.init(x: -12, y: -1), size: CGSize(width: 24, height: 2)))
        shapeNode.strokeColor = Constants.TimeWarp.barColor
        shapeNode.fillColor = Constants.TimeWarp.barColor
        return shapeNode
    }()

    private lazy var emitter: SKEmitterNode = {
        let emitter = SKEmitterNode(fileNamed: "TimeWarpParticle")!
        return emitter
    }()

    private var warpSubId: SubscriptionUUID!

    override init() {
        super.init()
        addChild(barNode)
        addChild(emitter)
        warpSubId = Timekeeper.default.subscribe(didUpdate: { [weak self] (_) in
            let recentWarpSpeed = Timekeeper.default.recentWarpSpeed
            if recentWarpSpeed == 0 {
                self?.emitter.particleBirthRate = 0
                self?.emitter.particleSpeed = 0
                return
            } else if recentWarpSpeed < 0 {
                self?.emitter.emissionAngle = -CGFloat.pi / 2
                self?.emitter.position = CGPoint(x: 0, y: -2)
            } else {
                self?.emitter.emissionAngle = CGFloat.pi / 2
                self?.emitter.position = CGPoint(x: 0, y: 2)
            }
            let interp = Easing(easingMethod: .quadraticEaseOut, startValue: 0, endValue: 250)
            let percentage = abs(recentWarpSpeed > 0 ? log(recentWarpSpeed) : -log(-recentWarpSpeed)).cap(toRange: 0..<15) / 15
            self?.emitter.particleSpeed = CGFloat(interp.value(at: percentage))
            self?.emitter.particleSpeedRange = CGFloat(interp.value(at: percentage) / 10)
            self?.emitter.particleBirthRate = CGFloat(interp.value(at: percentage) * 1.5)
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Timekeeper.default.unsubscribe(warpSubId)
    }
}
