//
//  TrackingLabelNode.swift
//  Graviton
//
//  Created by Ben Lu on 3/31/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import MathUtil
import SceneKit
import UIKit

class TrackingLabelNode: SCNNode {
    private static let surfaceShader: String = {
        let path = Bundle.main.path(forResource: "tracking_label.surface", ofType: "shader")!
        return try! String(contentsOfFile: path, encoding: .utf8)
    }()

    private static let geometryShader: String = {
        let path = Bundle.main.path(forResource: "tracking_label.geometry", ofType: "shader")!
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

    let offset: CGVector
    var fontColor: UIColor? {
        get {
            return geometry?.firstMaterial?.diffuse.contents as? UIColor
        }
        set {
            geometry?.firstMaterial?.diffuse.contents = newValue
        }
    }

    init(string: String?, textStyle: TextStyle? = nil, offset: CGVector = CGVector.zero) {
        self.offset = offset
        super.init()
        let style = textStyle ?? TextStyle.defaultTextStyle(fontSize: 0.8)
        let text = SCNText(string: nullable(style.textTransform)(string), extrusionDepth: 0)
        text.font = style.font
        text.flatness = 0.01
        geometry = text
        position = SCNVector3Zero
        let (min, max) = boundingBox
        // The offset to center the text
        let textOffset = -min - SCNVector3((max.x - min.x) / 2, 0, 0)
        text.containerFrame = CGRect(origin: CGPoint(x: CGFloat(textOffset.x), y: CGFloat(textOffset.y)), size: CGSize(width: 8, height: style.font.pointSize * 2))
        let material = text.firstMaterial!
        material.diffuse.contents = style.color
        material.locksAmbientWithDiffuse = true
        material.shaderModifiers = [
            .geometry: TrackingLabelNode.geometryShader,
            .surface: TrackingLabelNode.surfaceShader,
        ]
        material.setValue(offset.dx, forKeyPath: "horizontalOffset")
        material.setValue(offset.dy, forKeyPath: "verticalOffset")
    }

    convenience override init() {
        self.init(string: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
