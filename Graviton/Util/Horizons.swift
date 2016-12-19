//
//  Horizons.swift
//  Horizons
//
//  Created by Ben Lu on 9/28/16.
//
//

import Foundation

public class Horizons {
    static let serviceAddress = InternetAddress(hostname: "horizons.jpl.nasa.gov", port: 6775)
    
    public let queryObjects: [String]
    
    init(queryObjects: [String]) {
        self.queryObjects = queryObjects
    }
    
    public func query(itemCompletion: ((String, String) -> Void)?, completion: @escaping ([String: String]?) -> Void) {
        DispatchQueue.global().async {
            var targets = self.queryObjects
            var rawEphemeris = [String: String]()
            Horizons.serviceAddress.open()
                .printOnReceive()
                .stop(when: { _ in targets.isEmpty })
                .replyOnce(to: "Horizons>", reply: { _ in "Sun" })
                .returnOnce(on: "[E]phemeris")
                .reply(to: "Horizons>", reply: { _ in targets.first! })
                .reply(to: "[E]phemeris", reply: { _ in "E" })
                .reply(to: "Observe, Elements, Vectors", reply: { _ in "e" })
                .reply(to: "Coordinate system center", reply: { _ in "Sun" })
                .reply(to: "Reference plane [eclip, frame, body ]", reply: { _ in "eclip" })
                .reply(to: "Starting TDB", reply: { _ in "2016-Sep-29 {00:00}" })
                .reply(to: "Ending   TDB", reply: { _ in "2016-Sep-29 {00:01}" })
                .reply(to: "Output interval", reply: { _ in "1d" })
                // configure once
                .replyOnce(to: "Accept default output", reply: { _ in "n" })
                // after first config, no need to do subsequent ones
                .reply(to: "Accept default output", reply: { _ in "y" })
                .replyOnce(to: "Output reference frame [J2000, B1950]", reply: { _ in "J2000" })
                .replyOnce(to: "Output units [1=KM-S, 2=AU-D, 3=KM-D]", reply: { _ in "1" })
                .replyOnce(to: "Spreadsheet CSV format", reply: { _ in "YES" })
                .returnOnce(on: "Output delta-T (TDB-UT)   [ YES, NO ]")
                .replyOnce(to: "Type of periapsis time", reply: { _ in "ABS" })
                .reply(to: "Select... [A]gain, [N]ew-case,", reply: { _ in "N" })
                .onMatch("\\$\\$SOE\\s*(([^,]*,\\s*)*)\\s*\\$\\$EOE") { (fullText, matches) in
                    let target = targets.removeFirst()
                    if matches.count > 1 {
                        fatalError()
                    }
                    let dataText = (fullText as NSString).substring(with: matches[0].rangeAt(1))
                    rawEphemeris[target] = dataText
                    itemCompletion?(target, dataText)
                }.timedOut { (_, _) in
                    print("timeout triggered")
                    completion(nil)
                }.succeeded { (_, _) in
                    print(rawEphemeris)
                    completion(rawEphemeris)
                }.start()
        }
    }
}
