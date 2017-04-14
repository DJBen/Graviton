//
//  IndicatorNode.swift
//  Graviton
//
//  Created by Sihao Lu on 4/14/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

extension ObserverScene {
    class IndicatorNode: BooleanFlaggedNode {
        override var isSetUp: Bool {
            return true
        }
        
        var indicatorNode: SCNNode
        
        init(setting: Settings.BooleanSetting, position: SCNVector3, color: UIColor) {
            indicatorNode = SCNNode(geometry: SCNPlane(width: 0.2, height: 0.2))
            indicatorNode.position = position
            indicatorNode.geometry!.firstMaterial!.diffuse.contents = color
            indicatorNode.geometry!.firstMaterial!.transparent.contents = #imageLiteral(resourceName: "annotation_cross")
            indicatorNode.constraints = [SCNBillboardConstraint()]
            super.init(setting: setting)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func setUpElement() { }
        
        override func showElement() {
            indicatorNode.constraints = [SCNBillboardConstraint()]
            addChildNode(indicatorNode)
        }
        
        override func hideElement() {
            indicatorNode.removeFromParentNode()
        }
        
        override func removeElement() {
            hideElement()
        }
    }
}
