//
//  BooleanFlaggedLight.swift
//  Graviton
//
//  Created by Sihao Lu on 5/21/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

class BooleanFlaggedLight: SCNLight, ObserverSceneElement {

    private var onConfig: (SCNLight) -> Void
    private var offConfig: (SCNLight) -> Void

    init(setting: Settings.BooleanSetting, on onConfig: @escaping (SCNLight) -> Void, off offConfig: @escaping (SCNLight) -> Void) {
        self.onConfig = onConfig
        self.offConfig = offConfig
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

    // MARK: - Observer Scene Element
    var isSetUp: Bool {
        return true
    }

    func showElement() {
        self.onConfig(self)
    }

    func hideElement() {
        self.offConfig(self)
    }

    func setUpElement() { }

    func removeElement() { }
}
