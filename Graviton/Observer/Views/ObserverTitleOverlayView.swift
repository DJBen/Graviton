//
//  ObserverTitleOverlayView.swift
//  Graviton
//
//  Created by Sihao Lu on 12/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

protocol ObserverTitleOverlayViewDelegate: NSObjectProtocol {
    func titleOverlayTapped(view: ObserverTitleOverlayView)
    func titleOverlayFocusTapped(view: ObserverTitleOverlayView)
}

class ObserverTitleOverlayView: UIView {
    private lazy var blurEffect = UIBlurEffect(style: .dark)

    private lazy var blurEffectView: UIVisualEffectView = {
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        return blurEffectView
    }()

    lazy var titleButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.setTitleColor(#colorLiteral(red: 0.9679985642, green: 0.9959152341, blue: 0.9657947421, alpha: 1), for: [.normal, .highlighted])
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22.0)
        button.titleLabel?.textAlignment = .center
        button.setTitle("<Title>", for: .normal)
        button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
        return button
    }()

    lazy var focusButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.setImage(#imageLiteral(resourceName: "menu_icon_target"), for: .normal)
        button.addTarget(self, action: #selector(focusTapped(sender:)), for: .touchUpInside)
        return button
    }()

    var title: String? {
        get {
            return titleButton.titleLabel?.text
        }
        set {
            titleButton.setTitle(newValue, for: .normal)
        }
    }

    weak var delegate: ObserverTitleOverlayViewDelegate?

    private lazy var vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
    private lazy var vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(blurEffectView)
        vibrancyEffectView.frame = bounds
        vibrancyEffectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(titleButton)
        blurEffectView.contentView.addSubview(vibrancyEffectView)
        vibrancyEffectView.contentView.addSubview(focusButton)
        focusButton.frame = CGRect(x: vibrancyEffectView.contentView.bounds.width - 60, y: 0, width: 60, height: 44)
        focusButton.autoresizingMask = .flexibleLeftMargin
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        titleButton.addConstraint(titleButton.heightAnchor.constraint(equalToConstant: 44))
        addConstraints(
            [
                titleButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
                titleButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -60),
                titleButton.topAnchor.constraint(equalTo: topAnchor),
            ]
        )
    }

    required init?(coder _: NSCoder) {
        fatalError("Not implemented")
    }

    @objc func buttonTapped(sender _: UIButton) {
        delegate?.titleOverlayTapped(view: self)
    }

    @objc func focusTapped(sender _: UIButton) {
        delegate?.titleOverlayFocusTapped(view: self)
    }
}
