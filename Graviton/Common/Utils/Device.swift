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

    /// Starting from `iOS 11.2.*`, the SceneKit seemingly does not render transparent textures.
    ///
    /// - seealso: [This](https://forums.developer.apple.com/thread/92671) apple forum thread.
    static var isSceneKitBroken: Bool {
        let os = ProcessInfo().operatingSystemVersion
        switch (os.majorVersion, os.minorVersion, os.patchVersion) {
        case (11, 2, _):
            return true
        default:
            return false
        }
    }
}
