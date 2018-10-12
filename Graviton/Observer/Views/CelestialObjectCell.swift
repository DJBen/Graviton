//
//  CelestialObjectCell.swift
//  Graviton
//
//  Created by Sihao Lu on 4/2/18.
//  Copyright © 2018 Ben Lu. All rights reserved.
//

import UIKit

class CelestialObjectCell: UITableViewCell {
    var textLabelLeftInset: CGFloat = 60
    var secondaryLabelRightInset: CGFloat = 25
    var secondaryLabelWidth: CGFloat = 120

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
        detailTextLabel?.textColor = Constants.Menu.secondaryTextColor
        detailTextLabel?.numberOfLines = 2
        detailTextLabel?.minimumScaleFactor = 0.7
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
        textLabel?.frame = CGRect(x: textLabelLeftInset, y: 0, width: contentViewSize.width - textLabelLeftInset - secondaryLabelWidth - secondaryLabelRightInset, height: contentViewSize.height)
        detailTextLabel?.frame = CGRect(x: contentViewSize.width - secondaryLabelWidth - secondaryLabelRightInset, y: 0, width: secondaryLabelWidth, height: contentViewSize.height)
    }
}
