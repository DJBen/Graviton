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

extension ObserverScene {
    class LineNode: BooleanFlaggedNode {
        enum Style {
            case dashed
        }
        
        private let color: UIColor
        
        private let vertices: [SCNVector3]

        private var lineNode: SCNNode?
        
        override var isSetUp: Bool {
            get {
                return lineNode != nil
            }
        }
        
        init(setting: Settings.BooleanSetting, vertices: [SCNVector3], color: UIColor) {
            self.vertices = vertices
            self.color = color
            super.init(setting: setting)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func drawLine() {
            let line = SCNGeometry.closedDashedPolyLine(vertices: vertices)
            lineNode = SCNNode(geometry: line)
            let mat = SCNMaterial()
            mat.diffuse.contents = color
            line.firstMaterial = mat
        }
        
        // MARK: ObserverSceneElement
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
}
