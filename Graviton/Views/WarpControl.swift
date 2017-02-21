//
//  WarpControl.swift
//  Graviton
//
//  Created by Ben Lu on 11/19/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit

struct WarpSpeed: CustomStringConvertible {
    
    var multiplier: Double = 1
    
    public var description: String {
        return WarpSpeed.formatter.string(from: NSNumber.init(value: multiplier))! + "x"
    }
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    static let speeds = [1, 5, 10, 100, 1000, 5000, 20000, 100000, 500000]
    
    mutating func cycle() {
        if multiplier >= Double(WarpSpeed.speeds.last!) {
            multiplier = 1
        } else {
            next()
        }
    }
    
    mutating func next() {
        if multiplier >= Double(WarpSpeed.speeds.last!) {
            multiplier = Double(WarpSpeed.speeds.last!)
        }
        for speed in WarpSpeed.speeds {
            if multiplier < Double(speed) {
                multiplier = Double(speed)
                break
            }
        }
    }
    
    mutating func previous() {
        if multiplier <= Double(WarpSpeed.speeds.first!) {
            multiplier = Double(WarpSpeed.speeds.first!)
        }
        for speed in WarpSpeed.speeds.reversed() {
            if multiplier > Double(speed) {
                multiplier = Double(speed)
                break
            }
        }
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
    
    func buttonTapped(sender: UIButton) {
        speed.cycle()
        self.sendActions(for: .touchUpInside)
        self.speedButton.setTitle(self.speed.description, for: .normal)
        self.sendActions(for: .valueChanged)
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
