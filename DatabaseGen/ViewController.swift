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

    let path = NSSearchPathForDirectoriesInDomains(
        .documentDirectory, .userDomainMask, true
        ).first!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func clean() {
        let enumerator = FileManager.default.enumerator(atPath: path)!
        while let filePath = enumerator.nextObject() as? String {
            try! FileManager.default.removeItem(atPath: (path as NSString).appendingPathComponent(filePath))
        }
    }
    
    private func ask(_ proceed: @escaping (UIAlertAction) -> Void) {
        if FileManager.default.fileExists(atPath: path) {
            let alert = UIAlertController(title: "Previous Data Exists", message: "Clean before fetching data?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Clean", style: .destructive, handler: { (action) in
                self.clean()
                proceed(action)
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: proceed))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func generateMoon(_ sender: UIButton) {
        func proceed(action: UIAlertAction) {
            let localMoonDataPath = Bundle.main.path(forResource: "moon_1500AD_to_3000AD", ofType: "result")!
            let localMoonData = try! String(contentsOfFile: localMoonDataPath)
            let _ = ResponseParser.parseEphemeris(content: localMoonData, save: true)
        }
        ask(proceed)
    }
    
    @IBAction func fetchMajorPlanets(_ sender: UIButton) {
        
    }
    
    @IBAction func fetchMoon(_ sender: UIButton) {
        func proceed(action: UIAlertAction) {
            let moon = Naif.moon(.moon)
            let calendar = Calendar(identifier: .gregorian)
            let current = Date()
            func fetch(offset: Int, terminatingOffset: Int = 360) {
                if offset >= terminatingOffset {
                    return
                }
                let date = calendar.date(byAdding: .month, value: offset, to: current)!
                let monthComponents = calendar.dateComponents([.era, .year, .month], from: date)
                let month = calendar.date(from: monthComponents)!
                Horizons.shared.fetchEphemeris(preferredDate: month, naifs: [moon], mode: .onlineOnly, update: { (ephemeris) in
                    print(offset)
                    print(ephemeris[moon.rawValue] as Any)
                }) { (ephemeris, error) in
                    if let e = error {
                        print(e)
                    }
                    fetch(offset: offset + 1, terminatingOffset: terminatingOffset)
                }
            }
            fetch(offset: 240)
        }
        ask(proceed)
    }

}

