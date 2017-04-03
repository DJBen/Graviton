//
//  OrthographicLabelNode.swift
//  Graviton
//
//  Created by Ben Lu on 3/31/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import MathUtil

class OrthographicLabelNode: SCNNode {
    
    private static let surfaceShader: String = {
        let path = Bundle.main.path(forResource: "orthographic_label.surface", ofType: "shader")!
        return try! String(contentsOfFile: path, encoding: .utf8)
    }()
    
    private static let geometryShader: String = {
        let path = Bundle.main.path(forResource: "orthographic_label.geometry", ofType: "shader")!
        return try! String(contentsOfFile: path, encoding: .utf8)
    }()
    
    var string: String? {
        get {
            return (geometry as? SCNText)?.string as? String
        }
        set {
            (geometry as? SCNText)?.string = newValue
        }
    }
    
    init(string: String?) {
        super.init()
        let text = SCNText(string: string, extrusionDepth: 0)
        text.font = UIFont(name: "Palatino", size: 0.8)
        text.flatness = 0.05
        geometry = text
        position = SCNVector3Zero
        let (min, max) = self.boundingBox
        let offset = -min - SCNVector3((max.x - min.x) / 2, 0, 0)
        text.containerFrame = CGRect(origin: CGPoint(x: CGFloat(offset.x), y: CGFloat(offset.y)), size: CGSize(width: 8, height: 1.6))
        let material = text.firstMaterial!
        material.diffuse.contents = #colorLiteral(red: 0.8840664029, green: 0.9701823592, blue: 0.899977088, alpha: 0.8)
        material.shaderModifiers = [
            .geometry : OrthographicLabelNode.geometryShader,
            .surface : OrthographicLabelNode.surfaceShader
        ]
        material.setValue(0.0, forKeyPath: "horizontalOffset")
        material.setValue(0.0, forKeyPath: "verticalOffset")
    }
    
    override convenience init() {
        self.init(string: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
