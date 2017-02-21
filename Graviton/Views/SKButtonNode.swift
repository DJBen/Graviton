//
//  SKButtonNode.swift
//  Graviton
//
//  Created by Sihao Lu on 2/19/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import SpriteKit

// http://stackoverflow.com/questions/19082202/setting-up-buttons-in-skscene
class SKButtonNode: SKSpriteNode {
    
    enum SKButtonActionType: Int {
        case touchUpInside = 1,
        touchDown, touchUp
    }
    
    var isEnabled: Bool = true {
        didSet {
            if (disabledTexture != nil) {
                texture = isEnabled ? defaultTexture : disabledTexture
            }
        }
    }
    var isSelected: Bool = false {
        didSet {
            texture = isSelected ? selectedTexture : defaultTexture
        }
    }
    var defaultTexture: SKTexture
    var selectedTexture: SKTexture
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(normalTexture defaultTexture: SKTexture, selectedTexture: SKTexture, disabledTexture: SKTexture?) {
        self.defaultTexture = defaultTexture
        self.selectedTexture = selectedTexture
        self.disabledTexture = disabledTexture
        super.init(texture: defaultTexture, color: UIColor.white, size: defaultTexture.size())
        isUserInteractionEnabled = true
        
        // Adding this node as an empty layer. Without it the touch functions are not being called
        // The reason for this is unknown when this was implemented...?
        let bugFixLayerNode = SKSpriteNode(texture: nil, color: UIColor.clear, size: defaultTexture.size())
        bugFixLayerNode.position = self.position
        addChild(bugFixLayerNode)
    }
    
    /**
     * Taking a target object and adding an action that is triggered by a button event.
     */
    func setTarget(_ target: AnyObject, action: Selector, triggerEvent event: SKButtonActionType) {
        switch (event) {
        case .touchUpInside:
            targetTouchUpInside = target
            actionTouchUpInside = action
        case .touchDown:
            targetTouchDown = target
            actionTouchDown = action
        case .touchUp:
            targetTouchUp = target
            actionTouchUp = action
        }
        
    }
    
    var disabledTexture: SKTexture?
    var actionTouchUpInside: Selector?
    var actionTouchUp: Selector?
    var actionTouchDown: Selector?
    weak var targetTouchUpInside: AnyObject?
    weak var targetTouchUp: AnyObject?
    weak var targetTouchDown: AnyObject?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (!isEnabled) {
            return
        }
        isSelected = true
        if let ttd = targetTouchDown, let atd = actionTouchDown, ttd.responds(to: atd) {
            UIApplication.shared.sendAction(atd, to: ttd, from: self, for: nil)
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (!isEnabled) {
            return
        }
        guard let touch: UITouch = touches.first else { return }
        let touchLocation = touch.location(in: parent!)
        if (frame.contains(touchLocation)) {
            isSelected = true
        } else {
            isSelected = false
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (!isEnabled) {
            return
        }
        isSelected = false
        if let tti = targetTouchUpInside, let atui = actionTouchUpInside, tti.responds(to: atui) {
            guard let touch = touches.first else { return }
            let touchLocation = touch.location(in: parent!)
            
            if (frame.contains(touchLocation) ) {
                UIApplication.shared.sendAction(actionTouchUpInside!, to: targetTouchUpInside, from: self, for: nil)
            }
        }
        if let ttu = targetTouchUp, let atu = actionTouchUp, ttu.responds(to: atu) {
            UIApplication.shared.sendAction(actionTouchUp!, to: targetTouchUp, from: self, for: nil)
        }
    }
}
