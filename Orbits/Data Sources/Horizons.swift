//
//  Horizons.swift
//  StarCatalog
//
//  Created by Sihao Lu on 12/20/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation
import SpaceTime

// Example request
// http://ssd.jpl.nasa.gov/horizons_batch.cgi?batch=1&CENTER='SUN'&COMMAND='399'&MAKE_EPHEM='YES'%20&TABLE_TYPE='elements'&START_TIME='2017-01-01'&STOP_TIME='2017-01-02'&STEP_SIZE='1'&QUANTITIES='1,9,20,23,24'&CSV_FORMAT='YES'

public class Horizons {
    public static let shared: Horizons = {
        return Horizons()
    }()
    static let batchUrl = "http://ssd.jpl.nasa.gov/horizons_batch.cgi"
    static let trialCountLimit = 4
    // back off time should be the following value * pow(CONSTANT, numberOfTrials)
    // usually CONSTANT = 2
    static let trialBackoffTimeInterval: TimeInterval = 0.5
    static let timeIntervalBetweenJobs: TimeInterval = 0.4
    
    private var tasksTrialCount: [URL: Int] = [:]
    private var rawData: [Int: String] = [:]
    private var errors: [Error] = []
    
    func mergeCelestialBodies(_ b1: Set<CelestialBody>, _ b2: Set<CelestialBody>, refTime: Date = Date()) -> Set<CelestialBody> {
        var result = b1
        let jd = JulianDate(date: refTime).value
        for body2 in b2 {
            if let index = b1.index(of: body2) {
                let body = b1[index]
                if let mm1 = body.motion as? OrbitalMotionMoment, let mm2 = body2.motion as? OrbitalMotionMoment {
                    if abs(mm1.ephemerisJulianDate - jd) > abs(mm2.ephemerisJulianDate - jd) {
                        result.insert(body2)
                    }
                } else {
                    if body.motion is OrbitalMotionMoment {
                        result.insert(body2)
                    }
                }
            } else {
                result.insert(body2)
            }
        }
        return result
    }
    
    /// Fetch ephemeris of major bodies and moons
    ///
    /// - Parameters:
    ///   - preferredDate: The preferred date of ephemeris
    ///   - offline: When set to `true`, return immediately if local data is available and do not attempt to fetch online
    ///   - update: Called when planet data is ready; may never be called or be called multiple times
    ///   - complete: Block to execute upon completion
    public func fetchEphemeris(preferredDate: Date = Date(), naifs: [Naif] = Naif.planets, offline: Bool = false, update: ((Ephemeris) -> Void)? = nil, complete: ((Ephemeris?, [Error]?) -> Void)? = nil) {
        var shouldIncludeSun: Bool = false
        // load local data
        var cachedBodies = Set<CelestialBody>(naifs.flatMap {
            CelestialBody.load(naifId: $0.rawValue)
        })
        if cachedBodies.isEmpty == false {
            if naifs.contains(Naif.sun) {
                cachedBodies.insert(Sun.sol)
            }
            update?(Ephemeris(solarSystemBodies: cachedBodies))
            if offline {
                complete?(Ephemeris(solarSystemBodies: cachedBodies), nil)
                return
            }
        }
        
        // load online data
        let group = DispatchGroup()
        func taskComplete(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
            defer {
                group.leave()
            }
            
            // exponential back off retry
            func retry(url: URL) -> Bool {
                let trialCount = self.tasksTrialCount[url] ?? 0
                guard trialCount < Horizons.trialCountLimit else {
                    return false
                }
                let timeInterval: TimeInterval = Horizons.trialBackoffTimeInterval * (pow(2.0, Double(trialCount)))
                tasksTrialCount[url] = trialCount + 1
                group.enter()
                DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) {
                    let retryUrl = url
                    let retryTask = URLSession.shared.dataTask(with: retryUrl, completionHandler: taskComplete)
                    retryTask.resume()
                }
                return true
            }
            
            if let e = error as? NSError {
                if !retry(url: e.userInfo[NSURLErrorFailingURLErrorKey] as! URL) {
                    self.errors.append(e)
                }
            } else if let d = data {
                let httpResponse = response as! HTTPURLResponse
                let url = httpResponse.url!
                let utf8String = String(data: d, encoding: .utf8)!
                switch ResponseValidator.parse(content: utf8String) {
                case .busy:
                    print("busy: \(url), retrying")
                    let retried = retry(url: url)
                    if retried == false {
                        // retries run out
                        print("stop retrying: \(url)")
                    }
                default:
                    self.rawData[url.naifId!] = utf8String
                    print("complete: \(url) - \(d)")
                }
            } else {
                print("reponse has no data: \(response)")
            }
        }
        let tasks = HorizonsQuery.ephemerisQuery(naifs, date: preferredDate).flatMap { (query) -> URLSessionTask? in
            if query.command == Sun.sol.naifId {
                shouldIncludeSun = true
                return nil
            }
            return URLSession.shared.dataTask(with: query.url, completionHandler: taskComplete)
        }
        tasks.enumerated().forEach { (index: Int, task: URLSessionTask) in
            group.enter()
            let timeInterval: TimeInterval = Horizons.timeIntervalBetweenJobs * Double(index)
            DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) {
                task.resume()
            }
        }
        group.notify(queue: .main) {
            defer {
                self.tasksTrialCount.removeAll()
                self.errors.removeAll()
                self.rawData.removeAll()
            }
            guard self.errors.isEmpty else {
                print("complete with failure: fetching celestial bodies")
                if cachedBodies.isEmpty {
                    complete?(nil, self.errors)
                } else {
                    let eph = Ephemeris(solarSystemBodies: cachedBodies)
                    complete?(eph, self.errors)
                }
                return
            }
            print("complete: fetching celestial bodies")
            var bodies = Set<CelestialBody>(self.rawData.flatMap { (naif, content) -> CelestialBody? in
                if let body = ResponseParser.parse(content: content) {
                    body.save()
                    return body
                }
                return nil
            })
            if shouldIncludeSun {
                bodies.insert(Sun.sol)
            }
            let merged = self.mergeCelestialBodies(cachedBodies, bodies, refTime: preferredDate)
            let eph = Ephemeris(solarSystemBodies: merged)
            update?(eph)
            complete?(eph, nil)
        }
    }
}

fileprivate extension URL {
    var naifId: Int? {
        if let components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
            if let items = components.queryItems {
                let filtered = items.filter { $0.name == "COMMAND" }
                guard filtered.isEmpty == false else { return nil }
                guard let str = filtered[0].value else { return nil }
                let start = str.index(str.startIndex, offsetBy: 1)
                let end = str.index(str.endIndex, offsetBy: -1)
                return Int(str.substring(with: start..<end))
            }
        }
        return nil
    }
}
