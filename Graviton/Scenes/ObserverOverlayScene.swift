//
//  ObserverOverlayScene.swift
//  Graviton
//
//  Created by Ben Lu on 2/4/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SpriteKit
import Orbits
import StarryNight
import MathUtil

class ObserverOverlayScene: SKScene {
    enum AnnotationClass {
        case planets
        case stars
        case sun
    }
    
    private var constellationParentNode: SKNode = SKNode()

    public override init(size: CGSize) {
        super.init(size: size)
        setupScene()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupScene() {
        addChild(constellationParentNode)
    }
    
    func showConstellationLabels(info: [Constellation: CGPoint]) {
        let screenCenter = CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height / 2)
        info.forEach { (key, value) in
            let easing = Easing(easingMethod: .cubicEaseIn, startValue: 1, endValue: 0)
            let linear = Easing.init(startValue: Double(min(screenCenter.x, screenCenter.y)), endValue: Double(max(screenCenter.x, screenCenter.y)))
            var ratio = (value - screenCenter).length / CGFloat(linear.value(at: 0.7))
            ratio = clamp(ratio, minValue: 0, maxValue: 1)
            let alpha = easing.value(at: Double(ratio))
            if let conNode = self.constellationParentNode.childNode(withName: key.iAUName) {
                conNode.position = value
                conNode.alpha = CGFloat(alpha)
                return
            }
            let conNode = SKLabelNode(fontNamed: "Palatino")
            conNode.text = key.name
            conNode.position = value
            conNode.alpha = CGFloat(alpha)
            conNode.fontColor = #colorLiteral(red: 0.8840664029, green: 0.9701823592, blue: 0.899977088, alpha: 0.8)
            conNode.fontSize = 14
            conNode.name = key.iAUName
            self.constellationParentNode.addChild(conNode)
        }
        let nodesToDelete = self.constellationParentNode.children.filter { (node) -> Bool in
            return info.keys.map { $0.iAUName }.contains(node.name!) == false
        }
        nodesToDelete.forEach { $0.removeFromParent() }
    }
    
    func annotate(_ name: String, annotation: String, position: CGPoint, `class`: AnnotationClass = .stars, isVisible: Bool = true) {
        func offset(_ position: CGPoint, `class`: AnnotationClass) -> CGPoint {
            var offsetY: CGFloat = -15
            switch `class` {
            case .sun:
                offsetY = -25
            default:
                break
            }
            return position + CGVector(dx: 0, dy: offsetY)
        }
        if let node = childNode(withName: name) {
            node.position = offset(position, class: `class`)
            node.isHidden = !isVisible
        } else {
            let node = SKLabelNode(fontNamed: "Palatino")
            let fontSize: CGFloat
            let color: UIColor
            switch `class` {
            case .planets:
                fontSize = 12
                color = #colorLiteral(red: 0.9616846442, green: 0.930521369, blue: 0.8593300581, alpha: 1)
            case .stars:
                fontSize = 12
                color = #colorLiteral(red: 0.8279239535, green: 0.9453579783, blue: 0.9584422708, alpha: 1)
            case .sun:
                fontSize = 15
                color = #colorLiteral(red: 0.9517338872, green: 0.8350647092, blue: 0.8214485049, alpha: 1)
            }
            node.fontSize = fontSize
            node.fontColor = color
            node.text = annotation
            node.name = name
            node.position = offset(position, class: `class`)
            node.isHidden = !isVisible
            addChild(node)
        }
    }
}
