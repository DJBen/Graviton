//
//  Menu.swift
//  Graviton
//
//  Created by Sihao Lu on 2/25/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

enum MenuParseError: Error {
    case missingSectionContent
    case missingMenuText
    case missingMenuType
    case unrecognizedMenuType
    case missingDestination
    case menuFileNotFound
    case missingBinding
    case cannotFindBinding
    case cannotFindSelector
    case cannotInitializeClassName
}

struct Menu {
    static var main: Menu = {
        let path = Bundle.main.path(forResource: "main_menu", ofType: "plist")!
        return try! Menu.init(filePath: path)
    }()

    let sections: [Section]

    init(filePath: String) throws {
        guard let rawSections = NSArray(contentsOfFile: filePath) as? [[String: AnyObject]] else {
            throw MenuParseError.menuFileNotFound
        }
        var sections = [Section]()
        for rawSection in rawSections {
            sections.append(try Section.init(rawSection: rawSection))
        }
        self.sections = sections
    }

    /// Register conditional disabling
    ///
    /// - Returns: A list of settings to observe
    func registerAllConditionalDisabling() -> [Settings.BooleanDisableBehavior] {
        var behaviors: [Settings.BooleanDisableBehavior] = []
        sections.forEach { (section) in
            section.items.forEach { (item) in
                if case let .toggle(_, behavior) = item.type {
                    if let behavior = behavior {
                        Settings.default.addConditionalDisabling(behavior)
                        behaviors.append(behavior)
                    }
                }
            }
        }
        return behaviors
    }

    subscript(indexPath: IndexPath) -> MenuItem {
        let (s, r) = (indexPath.section, indexPath.row)
        return sections[s].items[r]
    }
}

struct Section {
    let name: String?
    let items: [MenuItem]

    init(name: String?, items: [MenuItem]) {
        self.name = name
        self.items = items
    }

    init(rawSection: [String: AnyObject]) throws {
        guard let sectionContent = rawSection["content"] as? [[String: AnyObject]] else { throw MenuParseError.missingSectionContent }
        name = rawSection["section"] as? String
        var items = [MenuItem]()
        for rawItem in sectionContent {
            items.append(try MenuItem.init(rawItem: rawItem))
        }
        self.items = items
    }
}

struct MenuItem {
    enum `Type` {
        case detail(Menu)
        case toggle(Settings.BooleanSetting, Settings.BooleanDisableBehavior?)
        case button(String, Any?)
    }
    let text: String
    let type: Type
    let image: UIImage?

    init(rawItem: [String: AnyObject]) throws {
        guard let text = rawItem["text"] as? String else { throw MenuParseError.missingMenuText }
        self.text = text
        guard let type = rawItem["type"] as? String else { throw MenuParseError.missingMenuType }
        switch type {
        case "detail":
            guard let submenuName = rawItem["destination"] as? String else { throw MenuParseError.missingDestination }
            guard let path = Bundle.main.path(forResource: submenuName, ofType: "plist") else { throw MenuParseError.menuFileNotFound }
            self.type = .detail(try Menu(filePath: path))
        case "toggle":
            guard let binding = rawItem["binding"] as? String else { throw MenuParseError.missingBinding }
            guard let field = Settings.BooleanSetting(rawValue: binding) else { throw MenuParseError.cannotFindBinding }
            if let disableCondition = rawItem["disableCondition"] as? [String: Any] {
                let dependent = Settings.BooleanSetting(rawValue: disableCondition["key"] as! String)!
                let condition = disableCondition["condition"] as! Bool
                let fallback = disableCondition["fallback"] as! Bool
                let behavior = Settings.BooleanDisableBehavior(setting: field, dependent: dependent, condition: condition, fallback: fallback)
                self.type = .toggle(field, behavior)
            } else {
                self.type = .toggle(field, nil)
            }
        case "button":
            guard let key = rawItem["key"] as? String else { throw MenuParseError.cannotFindSelector }
            let userInfo = rawItem["userInfo"]
            self.type = .button(key, userInfo)
        default:
            throw MenuParseError.unrecognizedMenuType
        }
        if let imageName = rawItem["image"] as? String {
            image = UIImage(named: imageName)
        } else {
            image = nil
        }
    }
}

extension Menu {
    func indexPath(for setting: Settings.BooleanSetting) -> IndexPath? {
        for (i, section) in sections.enumerated() {
            for (j, item) in section.items.enumerated() {
                if case let .toggle(field, _) = item.type {
                    if field == setting {
                        return IndexPath.init(row: j, section: i)
                    }
                }
            }
        }
        return nil
    }
}
