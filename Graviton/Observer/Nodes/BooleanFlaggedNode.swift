//
//  BooleanFlaggedObserverSceneNode.swift
//  Graviton
//
//  Created by Sihao Lu on 4/11/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

extension ObserverScene {
    class BooleanFlaggedNode: SCNNode, ObserverSceneElement {

        init(setting: Settings.BooleanSetting) {
            super.init()
            subscribe(setting: setting) { (_, shouldShow) in
                if shouldShow {
                    if self.isSetUp == false {
                        self.setUpElement()
                    }
                    self.showElement()
                } else {
                    self.hideElement()
                }
            }
            setUpElement()
            if Settings.default[setting] {
                showElement()
            } else {
                hideElement()
            }
        }
        
        deinit {
            unsubscribeFromSetting()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func subscribe(setting: Settings.BooleanSetting, valueChanged: @escaping BooleanSettingBlock) {
            Settings.default.subscribe(setting: setting, object: self, valueChanged: valueChanged)
        }

        private func unsubscribeFromSetting() {
            Settings.default.unsubscribe(object: self)
        }
        
        // MARK: ObserverSceneElement
        var isSetUp: Bool {
            fatalError("isSetUp is not implemented")
        }
        
        // abstract class: throw for these abstract methods
        
        func showElement() {
            doesNotRecognizeSelector(#selector(showElement))
        }
        
        func hideElement() {
            doesNotRecognizeSelector(#selector(hideElement))
        }
        
        func setUpElement() {
            doesNotRecognizeSelector(#selector(setUpElement))
        }
        
        func removeElement() {
            doesNotRecognizeSelector(#selector(removeElement))
        }
    }
}
