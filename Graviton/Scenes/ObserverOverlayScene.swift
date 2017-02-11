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
import MathUtil

class ObserverOverlayScene: SKScene {
    
    public override init(size: CGSize) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    enum AnnotationClass {
        case planets
        case stars
        case sun
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
