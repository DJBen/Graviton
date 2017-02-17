//
//  ViewController.swift
//  DatabaseGen
//
//  Created by Ben Lu on 2/16/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import Orbits
import SQLite

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func generateMoon(_ sender: UIButton) {
        let moon = Naif.moon(.moon)
        let calendar = Calendar(identifier: .gregorian)
        let monthComponents = calendar.dateComponents([.era, .year, .month], from: Date())
        let month = calendar.date(from: monthComponents)!
        
        Horizons.shared.fetchEphemeris(preferredDate: month, naifs: [moon], offline: false, update: { (ephemeris) in
            print(ephemeris[moon.rawValue] as Any)
        }) { (ephemeris, error) in
            print("complete")
            print(error as Any)
        }
    }


}

