//
//  FocusIndicatorNode.swift
//  Graviton
//
//  Created by Ben Lu on 4/26/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

class FocusIndicatorNode: SCNNode {
    private static let geometryShader: String = {
        let path = Bundle.main.path(forResource: "focus_indicator.geometry", ofType: "shader")!
        return try! String(contentsOfFile: path, encoding: .utf8)
    }()

    let color: UIColor
    let radius: Double

    private var lineNodes: [SCNNode] = []

    init(radius: Double = 0, color: UIColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)) {
        self.radius = radius
        self.color = color
        super.init()
        setupElements()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupElements() {
        lineNodes = (0..<4).map { (index) -> SCNNode in
            let angle = Double(index) * Double.pi / 2
            return generateLineNode(rotation: angle)
        }
        lineNodes.forEach { self.addChildNode($0) }
    }

    private func generateLineNode(rotation: Double) -> SCNNode {
        let line = SCNGeometry.openSolidPolyLine(vertices: [SCNVector3(0, 0, 0), SCNVector3(0.3, 0, 0)])
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.shaderModifiers = [
            .geometry : FocusIndicatorNode.geometryShader,
        ]
        mat.setValue(radius, forKeyPath: "radius")
        line.firstMaterial = mat
        let node = SCNNode(geometry: line)
        node.rotation = SCNVector4(0, 0, 1, rotation)
        return node
    }
}
