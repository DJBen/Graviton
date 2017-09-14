//
//  Style.swift
//  Graviton
//
//  Created by Ben Lu on 4/21/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

struct Style {
    static func setTabBarTransparent(tabBar: UITabBar) {
        tabBar.barTintColor = UIColor.clear
        tabBar.tintColor = UIColor.white
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
    }

    static func setTabBarNormal(tabBar: UITabBar) {
        tabBar.barStyle = .default
        tabBar.tintColor = nil
        tabBar.barTintColor = nil
        tabBar.backgroundImage = nil
        tabBar.shadowImage = nil
    }
}

struct TextStyle {
    struct Font {
        static func constellationLabelFont(size: CGFloat) -> UIFont {
            return UIFont(name: "CormorantSC-Regular", size: size)!
        }

        static func nearStellarBodyLabelFont(size: CGFloat) -> UIFont {
            return UIFont(name: "CormorantSC-Regular", size: size)!
        }

        static func defaultLabelFont(size: CGFloat) -> UIFont {
            return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.light)
        }

        static func monoLabelFont(size: CGFloat) -> UIFont {
            return UIFont.monospacedDigitSystemFont(ofSize: size, weight: UIFont.Weight.thin)
        }
    }

    let font: UIFont
    let color: UIColor
    let textTransform: (String) -> String

    private init(font: UIFont, color: UIColor, textTransform: @escaping (String) -> String = { $0 }) {
        self.font = font
        self.color = color
        self.textTransform = textTransform
    }

    static func defaultTextStyle(fontSize: CGFloat) -> TextStyle {
        let font = Font.defaultLabelFont(size: fontSize)
        let color = UIColor.white
        return TextStyle.init(font: font, color: color)
    }

    static func constellationLabelTextStyle(fontSize: CGFloat) -> TextStyle {
        let font = Font.constellationLabelFont(size: fontSize)
        let color = #colorLiteral(red: 0.8840664029, green: 0.9701823592, blue: 0.899977088, alpha: 0.8)
        return TextStyle.init(font: font, color: color, textTransform: { $0.capitalized })
    }

    static func nearStellarBodyTextStyle(fontSize: CGFloat, color: UIColor = #colorLiteral(red: 0.8840664029, green: 0.9701823592, blue: 0.899977088, alpha: 0.8)) -> TextStyle {
        let font = Font.constellationLabelFont(size: fontSize)
        return TextStyle.init(font: font, color: color)
    }
}
