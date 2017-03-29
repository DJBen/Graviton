//
//  OrthographicLabelNode.swift
//  Graviton
//
//  Created by Ben Lu on 3/31/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

class OrthographicLabelNode: SCNNode {
    
    private static let surfaceShader: String = {
        let path = Bundle.main.path(forResource: "orthographic_label.surface", ofType: "shader")!
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
        text.containerFrame = CGRect.init(origin: CGPoint(x: 0, y: -0.8), size: CGSize(width: 8, height: 1.6))
        text.firstMaterial?.shaderModifiers = [
            .surface : OrthographicLabelNode.surfaceShader
        ]
        text.firstMaterial?.diffuse.contents = #colorLiteral(red: 0.8840664029, green: 0.9701823592, blue: 0.899977088, alpha: 0.8)
        geometry = text
    }
    
    override convenience init() {
        self.init(string: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
