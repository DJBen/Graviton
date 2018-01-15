//
//  HeaderView.swift
//  Graviton
//
//  Created by Sihao Lu on 12/17/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

class HeaderView: UIView {
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()

    init() {
        super.init(frame: CGRect.zero)
        setupViewElements()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViewElements()
    }

    private func setupViewElements() {
        isOpaque = false
        addSubview(textLabel)
        addConstraints([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textLabel.topAnchor.constraint(equalTo: topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
