//
//  MenuLocationCell.swift
//  Graviton
//
//  Created by Sihao Lu on 8/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

class MenuLocationCell: MenuCell {
    override func setupView() {
        super.setupView()
        textLabel?.font = UIFont.systemFont(ofSize: 20)
        detailTextLabel?.font = UIFont.systemFont(ofSize: 15)
        detailTextLabel?.textColor = Constants.Menu.secondaryTextColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let contentViewSize = contentView.bounds.size
        textLabel?.frame = CGRect(x: 60, y: -10, width: contentViewSize.width - 60, height: contentViewSize.height)
        detailTextLabel?.frame = CGRect(x: 60, y: 30, width: contentViewSize.width - 60, height: contentViewSize.height - 35)
    }
}
