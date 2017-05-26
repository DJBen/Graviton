//
//  Settings.swift
//  Graviton
//
//  Created by Ben Lu on 2/22/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

fileprivate let constellationLineDefault: Settings.ConstellationLineSetting.Mode = .all
fileprivate let showCelestialEquatorDefault: Bool = true
fileprivate let showEclipticDefault: Bool = true
fileprivate let showConstellationLabelDefault: Bool = true
fileprivate let showPlanetLabelDefault: Bool = true
fileprivate let showMoonPhaseDefault: Bool = true
fileprivate let showEarthshineDefault = true
fileprivate let celestialEquatorDefaultColor: UIColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
fileprivate let eclipticDefaultColor: UIColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)

typealias BooleanSettingBlock = (Bool, Bool) -> Void

struct Settings {

    private struct BooleanSubscription {
        let setting: BooleanSetting
        let object: NSObject
        let block: BooleanSettingBlock
    }

    static var `default`: Settings = {
        return Settings()
    }()

    private var booleanSubscriptions = [BooleanSubscription]()

    private func findBooleanSubscriptions(_ key: BooleanSetting) -> [BooleanSubscription] {
        return booleanSubscriptions.filter { key == $0.setting }
    }

    private func executeBooleanBlock(setting: BooleanSetting, oldValue: Bool, newValue: Bool) {
        booleanSubscriptions.filter { setting == $0.setting }.forEach { $0.block(oldValue, newValue) }
    }

    enum BooleanSetting: String {
        case showCelestialEquator
        case showEcliptic
        case showConstellationLabel
        case showPlanetLabel
        case showNorthPoleIndicator
        case showSouthPoleIndicator
        case showMoonPhase
        case showEarthshine
        var `default`: Bool {
            switch self {
            case .showCelestialEquator:
                return showCelestialEquatorDefault
            case .showEcliptic:
                return showEclipticDefault
            case .showConstellationLabel:
                return showConstellationLabelDefault
            case .showPlanetLabel:
                return showPlanetLabelDefault
            case .showMoonPhase:
                return showMoonPhaseDefault
            case .showEarthshine:
                return showEarthshineDefault
            default:
                return false
            }
        }
    }

    enum ColorSetting: String {
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

    subscript(boolKey: BooleanSetting) -> Bool {
        get {
            guard let value = UserDefaults.standard.object(forKey: boolKey.rawValue) else { return boolKey.default }
            return value as! Bool
        }
        set {
            let oldValue = self[boolKey]
            executeBooleanBlock(setting: boolKey, oldValue: oldValue, newValue: newValue)
            UserDefaults.standard.set(newValue, forKey: boolKey.rawValue)
        }
    }

    subscript(colorKey: ColorSetting) -> UIColor {
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

    mutating func subscribe(setting: BooleanSetting, object: NSObject, valueChanged block: @escaping BooleanSettingBlock) {
        booleanSubscriptions.append(BooleanSubscription(setting: setting, object: object, block: block))
    }

    mutating func unsubscribe(object: NSObject) {
        booleanSubscriptions = booleanSubscriptions.filter { $0.object !== object }
    }
}
