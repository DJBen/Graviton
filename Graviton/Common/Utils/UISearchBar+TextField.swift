//
//  UISearchBar+TextField.swift
//  Graviton
//
//  Created by Sihao Lu on 9/15/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

extension UISearchBar {
    var textField: UITextField? {
        return self.value(forKey: "searchField") as? UITextField
    }
}
