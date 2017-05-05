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

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func switchValueChanged(sender: UISwitch) {
        guard let field = binding else { return }
        Settings.default[field] = sender.isOn
    }

    private func setupView() {
        accessoryView = toggle
        toggle.addTarget(self, action: #selector(switchValueChanged(sender:)), for: .valueChanged)
    }
}
