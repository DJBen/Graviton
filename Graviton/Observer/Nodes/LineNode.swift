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
        
        var color: UIColor {
            didSet {
                
            }
        }
        
        private let vertices: [SCNVector3]

        private var lineNode: SCNNode?
        
        override var isSetUp: Bool {
            get {
                return lineNode != nil
            }
        }
        
        init(setting: Settings.BooleanSetting, identifier: String, vertices: [SCNVector3], color: UIColor) {
            self.vertices = vertices
            self.color = color
            super.init(setting: setting, identifier: identifier)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func drawLine() {
            let numberOfVertices = vertices.count
            let indices = (0...numberOfVertices).map { CInt($0 % numberOfVertices) }
            let vertexSources = SCNGeometrySource(vertices: vertices)
            let elements = SCNGeometryElement(indices: indices, primitiveType: .line)
            let line = SCNGeometry(sources: [vertexSources], elements: [elements])
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
