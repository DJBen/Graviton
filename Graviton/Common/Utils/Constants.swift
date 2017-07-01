//
//  Constants.swift
//  Graviton
//
//  Created by Sihao Lu on 2/25/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

struct Constants {
    struct Menu {
        static let tintColor: UIColor = #colorLiteral(red: 0.8928905129, green: 0.9480869174, blue: 1, alpha: 1)
        static let textColor: UIColor = #colorLiteral(red: 0.9172289968, green: 0.86983639, blue: 0.8433859944, alpha: 1)
        static let highlightBackgroundColor: UIColor = #colorLiteral(red: 0.8595022559, green: 0.9733585715, blue: 1, alpha: 0.2989931778)
        static let separatorColor: UIColor = #colorLiteral(red: 0.8743273616, green: 1, blue: 0.9898142219, alpha: 0.2481018926)
        struct Button {
            static let textColor: UIColor = #colorLiteral(red: 0.8599745325, green: 0.9238263454, blue: 0.9425768426, alpha: 1)
            static let backgroundColor: UIColor = UIColor.clear
            static let font = UIFont.boldSystemFont(ofSize: 18)
        }
    }
    struct TimeWarp {
        static let textColor: UIColor = #colorLiteral(red: 0.8928905129, green: 0.9480869174, blue: 1, alpha: 1)
        static let barColor: UIColor = #colorLiteral(red: 0.8928905129, green: 0.9480869174, blue: 1, alpha: 1)
    }
    struct Observer {
        static let maximumDisplayMagnitude: Double = 5.2
    }
}
