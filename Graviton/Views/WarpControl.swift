//
//  WarpControl.swift
//  Graviton
//
//  Created by Ben Lu on 11/19/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit

struct WarpSpeed: CustomStringConvertible {
    private var mIndex: Int = 0

    var multiplier: Double {
        return Double(WarpSpeed.speeds[mIndex])
    }

    public var description: String {
        return WarpSpeed.descriptions[mIndex]
    }

    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()

    static let speeds = [1, 5, 10, 100, 1000, 3600, 3600 * 6, 86400, 86400 * 15, 86400 * 90, 86400 * 365, 86400 * 3650]
    static let descriptions = [
        "1x", "5x", "10x", "100x", "1000x", "1s=1h", "1s=6h", "1s=1d", "1s=15d", "1s=3m", "1s=1y", "1s=10y",
    ]

    mutating func next() {
        mIndex = (mIndex + 1) % WarpSpeed.speeds.count
    }

    mutating func prev() {
        mIndex = (mIndex - 1) % WarpSpeed.speeds.count
    }
}

class WarpControl: UIControl {
    var speed: WarpSpeed = WarpSpeed()

    lazy var speedButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(self.speed.description, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
        button.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), for: .highlighted)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    @objc func buttonTapped(sender _: UIButton) {
        speed.next()
        sendActions(for: .touchUpInside)
        speedButton.setTitle(speed.description, for: .normal)
        sendActions(for: .valueChanged)
    }

    private func setup() {
        addSubview(speedButton)
        let constraints: [NSLayoutConstraint] = [
            speedButton.topAnchor.constraint(equalTo: topAnchor),
            speedButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            speedButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            speedButton.leadingAnchor.constraint(equalTo: leadingAnchor),
        ]
        addConstraints(constraints)
    }
}
