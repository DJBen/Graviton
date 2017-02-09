//
//  StarScene.swift
//  Graviton
//
//  Created by Ben Lu on 2/4/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SpriteKit
import Orbits
import MathUtil

class StarScene: SKScene {
    
    lazy var starTexture = SKTexture(imageNamed: "star16x16")

    public override init(size: CGSize) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func drawStars(_ stars: [(DistantStar, CGPoint)]) {
        print("need to draw \(stars.count)")
        var namesOfNodesToRemove = Set<String>(children.flatMap { $0.name })
        let nodesRequiresDisplay = Set<String>(stars.map { String($0.0.identity.id) })
        namesOfNodesToRemove = namesOfNodesToRemove.subtracting(nodesRequiresDisplay)
        for (star, pos) in stars {
            if let onScreenNode = childNode(withName: String(star.identity.id)) {
                onScreenNode.position = pos
            } else {
                let size = radiusForMagnitude(star.physicalInfo.magnitude)
                let node = SKSpriteNode(texture: starTexture, color: UIColor.purple, size: CGSize(width: size, height: size))
                node.name = String(star.identity.id)
//                node.blendMode = .alpha
                node.position = pos
                addChild(node)
            }
        }
        print("cleaned \(namesOfNodesToRemove.count)")
        namesOfNodesToRemove.forEach { self.childNode(withName: $0)?.removeFromParent() }
        print(children.count)
    }
    
    private func radiusForMagnitude(_ mag: Double, blendOutStart: Double = 0, blendOutEnd: Double = 5) -> CGFloat {
        let maxSize: Double = 15
        let minSize: Double = 2
        let linearEasing = Easing(startValue: maxSize, endValue: minSize)
        let progress = mag / (blendOutEnd - blendOutStart)
        return CGFloat(linearEasing.value(at: progress))
    }
}
