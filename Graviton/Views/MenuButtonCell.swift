//
//  MenuButtonCell.swift
//  Graviton
//
//  Created by Sihao Lu on 6/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

typealias MenuButtonHandler = (String, Any?) -> Void

class MenuButtonCell: MenuCell {
    var key: String!
    var userInfo: Any?
    var handler: MenuButtonHandler?

    lazy var button: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(Constants.Menu.Button.textColor, for: .normal)
        button.backgroundColor = Constants.Menu.Button.backgroundColor
        button.titleLabel?.font = Constants.Menu.Button.font
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()

    override func setupView() {
        super.setupView()
        contentView.addSubview(button)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let contentViewSize = contentView.bounds.size
        textLabel?.isHidden = true
        imageView?.isHidden = true
        button.frame = CGRect(x: 20, y: 0, width: contentViewSize.width - 40, height: contentViewSize.height)
    }

    @objc func buttonTapped() {
        handler?(key, userInfo)
    }
}
