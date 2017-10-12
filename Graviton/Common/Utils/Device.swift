//
//  Device.swift
//  Graviton
//
//  Created by Sihao Lu on 10/12/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

struct Device {
    static var isiPhoneX: Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.window!.safeAreaInsets != UIEdgeInsets.zero
    }
}
