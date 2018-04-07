//
//  Settings.swift
//  Graviton
//
//  Created by Ben Lu on 2/22/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

private let constellationLineDefault: Settings.ConstellationLineSetting.Mode = .all
private let showCelestialEquatorDefault = true
private let showEclipticDefault = true
private let showMeridianDefault = false
private let showConstellationLabelDefault = true
private let showOrbitLineWhenFocusedDefault = true
private let showPlanetLabelDefault = true
private let showMoonPhaseDefault = true
private let showEarthshineDefault = true
private let showDirectionMarkersDefault = true
private let showZenithAndNadirMarkersDefault = true
private let stabilizeCameraDefault = false
private let enableTimeWarpDefault = true
private let useUtcTimeDefault = false
private let celestialEquatorDefaultColor: UIColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
private let eclipticDefaultColor: UIColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
private let groundTextureDefaultKey: String = "silverMountain"

typealias BooleanSettingBlock = (Bool, Bool) -> Void
typealias SelectionSettingBlock = (String, String) -> Void

struct Settings {

    struct BooleanDisableBehavior {
        let setting: BooleanSetting
        let dependent: BooleanSetting
        /// activate when dependent is at this value
        let condition: Bool
        /// set the setting to this value if not already when condition is met
        let fallback: Bool
    }

    private struct BooleanSubscription {
        let setting: BooleanSetting
        let object: NSObject
        let block: BooleanSettingBlock
    }

    private struct SelectionSettingSubscription {
        let setting: SelectionSetting
        let object: NSObject
        let block: SelectionSettingBlock
    }

    static var `default`: Settings = {
        return Settings()
    }()

    private var booleanSubscriptions = [BooleanSubscription]()
    private var selectionSubscriptions = [SelectionSettingSubscription]()
    private var disableBehaviors = [BooleanDisableBehavior]()

    private func findBooleanSubscriptions(_ key: BooleanSetting) -> [BooleanSubscription] {
        return booleanSubscriptions.filter { key == $0.setting }
    }

    private func executeBooleanBlock(setting: BooleanSetting, oldValue: Bool, newValue: Bool) {
        DispatchQueue.main.async {
            self.booleanSubscriptions.filter { setting == $0.setting }.forEach { $0.block(oldValue, newValue) }
        }
    }

    private func executeSelectionBlock(setting: SelectionSetting, oldValue: String, newValue: String) {
        DispatchQueue.main.async {
            self.selectionSubscriptions.filter { setting == $0.setting }.forEach { $0.block(oldValue, newValue) }
        }
    }

    enum BooleanSetting: String {
        case showCelestialEquator
        case showEcliptic
        case showOrbitLineWhenFocused
        case showConstellationLabel
        case showMeridian
        case showPlanetLabel
        case showNorthPoleIndicator
        case showSouthPoleIndicator
        case showMoonPhase
        case showEarthshine
        case showDirectionMarkers
        case stabilizeCamera
        case showZenithAndNadirMarkers
        case enableTimeWarp
        case useUtcTime
        case useAlphaInsteadOfBlurInSettings

        var `default`: Bool {
            switch self {
            case .showCelestialEquator:
                return showCelestialEquatorDefault
            case .showEcliptic:
                return showEclipticDefault
            case .showMeridian:
                return showMeridianDefault
            case .showOrbitLineWhenFocused:
                return showOrbitLineWhenFocusedDefault
            case .showConstellationLabel:
                return showConstellationLabelDefault
            case .showPlanetLabel:
                return showPlanetLabelDefault
            case .showMoonPhase:
                return showMoonPhaseDefault
            case .showEarthshine:
                return showEarthshineDefault
            case .showDirectionMarkers:
                return showDirectionMarkersDefault
            case .stabilizeCamera:
                return stabilizeCameraDefault
            case .showZenithAndNadirMarkers:
                return showZenithAndNadirMarkersDefault
            case .enableTimeWarp:
                return enableTimeWarpDefault
            case .useUtcTime:
                return useUtcTimeDefault
            case .useAlphaInsteadOfBlurInSettings:
                return false
            default:
                return false
            }
        }
    }

    enum SelectionSetting: String {
        case groundTexture
        case antialiasingMode
        var `default`: String {
            switch self {
            case .groundTexture:
                return groundTextureDefaultKey
            case .antialiasingMode:
                return "none"
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
            UserDefaults.standard.set(newValue, forKey: boolKey.rawValue)
            executeBooleanBlock(setting: boolKey, oldValue: oldValue, newValue: newValue)
            if let behavior = disableBehaviors.first(where: { $0.dependent == boolKey }), behavior.condition == newValue {
                let currentValue = self[behavior.setting]
                let targetValue = behavior.fallback
                if currentValue != targetValue {
                    self[behavior.setting] = behavior.fallback
                }
            }
        }
    }

    subscript(selectionKey: SelectionSetting) -> String {
        get {
            guard let value = UserDefaults.standard.object(forKey: selectionKey.rawValue) else { return selectionKey.default }
            return value as! String
        }
        set {
            let oldValue = self[selectionKey]
            UserDefaults.standard.set(newValue, forKey: selectionKey.rawValue)
            executeSelectionBlock(setting: selectionKey, oldValue: oldValue, newValue: newValue)
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

    mutating func addConditionalDisabling(_ behavior: BooleanDisableBehavior) {
        if disableBehaviors.contains(where: { $0.setting == behavior.setting }) {
            return
        }
        disableBehaviors.append(behavior)
    }

    mutating func removeConditionalDisabling(on setting: BooleanSetting) {
        if let index = disableBehaviors.index(where: { $0.setting == setting }) {
            disableBehaviors.remove(at: index)
        } else {
            preconditionFailure("cannot find conditional disabling on setting \(setting)")
        }
    }

    mutating func subscribe(setting: BooleanSetting, object: NSObject, valueChanged block: @escaping BooleanSettingBlock) {
        booleanSubscriptions.append(BooleanSubscription(setting: setting, object: object, block: block))
    }

    mutating func unsubscribe(object: NSObject) {
        booleanSubscriptions = booleanSubscriptions.filter { $0.object !== object }
        selectionSubscriptions = selectionSubscriptions.filter { $0.object !== object }
    }

    mutating func subscribe(setting: SelectionSetting, object: NSObject, valueChanged block: @escaping SelectionSettingBlock) {
        selectionSubscriptions.append(SelectionSettingSubscription(setting: setting, object: object, block: block))
    }

    mutating func subscribe(settings: [SelectionSetting], object: NSObject, valueChanged block: @escaping SelectionSettingBlock) {
        settings.forEach { self.subscribe(setting: $0, object: object, valueChanged: block) }
    }
}
