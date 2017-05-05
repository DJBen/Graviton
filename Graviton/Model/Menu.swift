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
        case toggle(Settings.BooleanSetting)
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
            self.type = .toggle(field)
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
