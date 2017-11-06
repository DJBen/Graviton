//
//  LineObserverSceneNode.swift
//  Graviton
//
//  Created by Ben Lu on 4/11/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import MathUtil

class LineNode: BooleanFlaggedNode {
    enum Style {
        case dashed
    }

    private let color: UIColor

    let vertices: [SCNVector3]

    var lineNode: SCNNode?

    var geometryToDraw: SCNGeometry {
        return SCNGeometry.closedDashedPolyLine(vertices: vertices)
    }

    override var isSetUp: Bool {
        return lineNode != nil
    }

    init(setting: Settings.BooleanSetting, vertices: [SCNVector3], color: UIColor) {
        self.vertices = vertices
        self.color = color
        super.init(setting: setting)
        categoryBitMask = ObserverScene.VisibilityCategory.nonMoon.rawValue
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func drawLine() {
        let line = geometryToDraw
        lineNode = SCNNode(geometry: line)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.locksAmbientWithDiffuse = true
        line.firstMaterial = mat
    }

    // MARK: - ObserverSceneElement
    override func setUpElement() {
        drawLine()
    }

    override func showElement() {
        if let node = lineNode, node.parent == nil {
            addChildNode(node)
        }
    }

    override func hideElement() {
        lineNode?.removeFromParentNode()
    }

    override func removeElement() {
        hideElement()
        lineNode = nil
    }
}
