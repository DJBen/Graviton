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
        
        private let identifier: String
        
        init(setting: Settings.BooleanSetting, identifier: String) {
            self.identifier = identifier
            super.init()
            Settings.default.subscribe(setting: setting, identifier: identifier) { (_, shouldShow) in
                if shouldShow {
                    if self.isSetUp == false {
                        self.setUpElement()
                    }
                    self.showElement()
                } else {
                    self.hideElement()
                }
            }
            name = identifier
        }
        
        deinit {
            Settings.default.unsubscribeSetting(withIdentifier: identifier)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: ObserverSceneElement
        var isSetUp: Bool {
            fatalError("isLoaded is not implemented")
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
