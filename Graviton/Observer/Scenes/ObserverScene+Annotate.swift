//
//  ObserverScene+Annotate.swift
//  Graviton
//
//  Created by Ben Lu on 4/4/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits
import StarryNight
import MathUtil

extension ObserverScene {
    enum AnnotationClass {
        case planet
        case star
        case sun
    }
    
    func drawConstellationLabels() {
        let conLabelNode = SCNNode()
        conLabelNode.name = "constellation labels"
        for constellation in Constellation.all {
            guard let c = constellation.displayCenter else { continue }
            let center = SCNVector3(c.normalized())
            let textNode = TrackingLabelNode(string: constellation.name)
            textNode.constraints = [SCNBillboardConstraint()]
            textNode.position = center * Float(auxillaryConstellationLabelLayerRadius)
            conLabelNode.addChildNode(textNode)
        }
        rootNode.addChildNode(conLabelNode)
    }
    
    func annotateCelestialBody(_ body: CelestialBody, position: SCNVector3, parent: SCNNode, `class`: AnnotationClass) {
        func offset(`class`: AnnotationClass) -> CGVector {
            switch `class` {
            case .sun:
                return CGVector(dx: 0, dy: -1)
            default:
                break
            }
            return CGVector(dx: 0, dy: -0.5)
        }
        if let node = parent.childNode(withName: String(body.naifId), recursively: false) {
            node.position = position.normalized() * Float(auxillaryConstellationLabelLayerRadius)
            node.constraints = [SCNBillboardConstraint()]
        } else {
            let fontSize: CGFloat
            let color: UIColor
            switch `class` {
            case .planet:
                fontSize = 0.8
                color = #colorLiteral(red: 0.9616846442, green: 0.930521369, blue: 0.8593300581, alpha: 1)
            case .star:
                fontSize = 0.7
                color = #colorLiteral(red: 0.8279239535, green: 0.9453579783, blue: 0.9584422708, alpha: 1)
            case .sun:
                fontSize = 0.9
                color = #colorLiteral(red: 0.9517338872, green: 0.8350647092, blue: 0.8214485049, alpha: 1)
            }
            let node = TrackingLabelNode(string: body.name, fontSize: fontSize, offset: offset(class: `class`))
            node.fontColor = color
            node.name = String(body.naifId)
            node.position = position.normalized() * Float(auxillaryConstellationLabelLayerRadius - 1)
            node.constraints = [SCNBillboardConstraint()]
            parent.addChildNode(node)
        }
    }
}
