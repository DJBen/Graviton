//
//  Settings.swift
//  Graviton
//
//  Created by Ben Lu on 2/22/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

fileprivate let constellationLineDefault: Settings.ConstellationLineSetting.Mode = .none
fileprivate let showCelestialEquatorDefault: Bool = true
fileprivate let showEclipticDefault: Bool = true
fileprivate let celestialEquatorDefaultColor: UIColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
fileprivate let eclipticDefaultColor: UIColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)

struct Settings {
    
    static var `default`: Settings = {
        return Settings()
    }()
    
    enum BooleanSettings: String {
        case showCelestialEquator
        case showEcliptic
        var `default`: Bool {
            switch self {
            case .showCelestialEquator:
                return showCelestialEquatorDefault
            case .showEcliptic:
                return showEclipticDefault
            }
        }
    }
    
    enum ColorSettings: String {
        case celestialEquatorColor
        case eclipticColor
        var `default`: UIColor {
            switch self {
            case .celestialEquatorColor:
                return celestialEquatorDefaultColor
            case .eclipticColor:
                return eclipticDefaultColor
            }
        }
    }
    
    enum ConstellationLineSetting: String {
        enum Mode: String {
            case center
            case all
            case none
        }
        case constellationLineMode
    }
    
    subscript(boolKey: BooleanSettings) -> Bool {
        get {
            guard let value = UserDefaults.standard.object(forKey: boolKey.rawValue) else { return boolKey.default }
            return value as! Bool
        }
        set {
            UserDefaults.standard.set(newValue, forKey: boolKey.rawValue)
        }
    }
    
    subscript(colorKey: ColorSettings) -> UIColor {
        get {
            guard let data = UserDefaults.standard.data(forKey: colorKey.rawValue) else { return colorKey.default }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as! UIColor
        }
        set {
            let data = NSKeyedArchiver.archivedData(withRootObject: newValue)
            UserDefaults.standard.set(data, forKey: colorKey.rawValue)
        }
    }
    
    subscript(conKey: ConstellationLineSetting) -> ConstellationLineSetting.Mode {
        get {
            guard let str = UserDefaults.standard.string(forKey: conKey.rawValue) else { return constellationLineDefault }
            return ConstellationLineSetting.Mode(rawValue: str)!
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: conKey.rawValue)
        }
    }
}
