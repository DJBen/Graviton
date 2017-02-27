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
    
    private func setupView() {
        accessoryView = toggle
    }
}
