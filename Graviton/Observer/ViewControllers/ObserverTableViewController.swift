//
//  ObserverTableViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 1/14/18.
//  Copyright © 2018 Ben Lu. All rights reserved.
//

import UIKit

class ObserverTableViewController: BaseTableViewController {
    override var prefersStatusBarHidden: Bool {
        return Device.isiPhoneX == false
    }
}
