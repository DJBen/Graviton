//
//  MenuCell.swift
//  Graviton
//
//  Created by Sihao Lu on 2/25/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

class MenuCell: UITableViewCell {
    var textLabelLeftInset: CGFloat = 60

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        imageView?.tintColor = Constants.Menu.tintColor
        textLabel?.textColor = Constants.Menu.textColor
        selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = Constants.Menu.highlightBackgroundColor
            return view
        }()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let contentViewSize = contentView.bounds.size
        imageView?.frame = CGRect(x: 21, y: (contentViewSize.height - 25) / 2, width: 25, height: 25)
        textLabel?.frame = CGRect(x: textLabelLeftInset, y: 0, width: contentViewSize.width - textLabelLeftInset, height: contentViewSize.height)
    }
}
