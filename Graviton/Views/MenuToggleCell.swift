//
//  MenuToggleCell.swift
//  Graviton
//
//  Created by Sihao Lu on 2/26/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

class MenuToggleCell: MenuCell {
    lazy var toggle: UISwitch = {
        let sw = UISwitch()
        return sw
    }()

    var binding: Settings.BooleanSetting? {
        didSet {
            if let field = binding {
                toggle.isOn = Settings.default[field]
            }
        }
    }

    @objc func switchValueChanged(sender: UISwitch) {
        guard let field = binding else { return }
        Settings.default[field] = sender.isOn
    }

    override func setupView() {
        super.setupView()
        accessoryView = toggle
        toggle.addTarget(self, action: #selector(switchValueChanged(sender:)), for: .valueChanged)
    }
}
