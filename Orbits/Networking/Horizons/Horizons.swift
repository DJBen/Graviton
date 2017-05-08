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

    let trialCountLimit = 4
    // Back off time should be the following value * pow(CONSTANT, numberOfTrials).
    // Usually CONSTANT = 2
    let trialBackoffTimeInterval: TimeInterval = 0.5
    let timeIntervalBetweenJobs: TimeInterval = 0.4

    func mergeCelestialBodies(_ b1: Set<CelestialBody>, _ b2: Set<CelestialBody>, refTime: Date = Date()) -> Set<CelestialBody> {
        var result = b1
        let jd = JulianDate(date: refTime)
        for body2 in b2 {
            if let index = b1.index(of: body2) {
                let body = b1[index]
                if let mm1 = body.motion as? OrbitalMotionMoment, let mm2 = body2.motion as? OrbitalMotionMoment {
                    if abs(mm1.ephemerisJulianDate - jd) > abs(mm2.ephemerisJulianDate - jd) {
                        result.update(with: body2)
                    }
                } else {
                    if body.motion is OrbitalMotionMoment {
                        result.update(with: body2)
                    }
                }
            } else {
                result.update(with: body2)
            }
        }
        return result
    }

    public enum FetchMode {
        /// Only fetch local data, return empty result if it doesn't exist
        case localOnly
        /// Only fetch online data if local data is not available
        case preferLocal
        /// Only fetch online data regardless of presence of local data
        case onlineOnly
        /// Return local data immediately and return fetched online data once that becomes available
        case mixed
    }

    public enum FetchStrategy {
        /// Kick off requests one after one
        case sequential
        /// Start all requests at the same time and retry at an exponentially growing interval whenever fails
        case exponentialBackoff
    }

    public func fetchOnlineRawData(queries: [HorizonsQuery], strategy: FetchStrategy = .exponentialBackoff, complete: @escaping ([Int: String], [Error]?) -> Void) {
        switch strategy {
        case .sequential:
            return fetchOnlineRawDataSequential(queries: queries, complete: complete)
        case .exponentialBackoff:
            return fetchOnlineRawDataExponentialBackoff(queries: queries, complete: complete)
        }
    }

    public func fetchOnlineRawDataSequential(queries: [HorizonsQuery], complete: @escaping ([Int: String], [Error]?) -> Void) {

        var rawData: [Int: String] = [:]
        var errors: [Error] = []

        func taskComplete(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
            let nsError = error as NSError?
            if let e = nsError {
                errors.append(e)
            } else if let d = data {
                let httpResponse = response as! HTTPURLResponse
                let url = httpResponse.url!
                let utf8String = String(data: d, encoding: .utf8)!
                switch ResponseValidator.default.parse(content: utf8String) {
                case .busy:
                    print("busy: \(url)")
                default:
                    rawData[url.naifId!] = utf8String
                    print("complete: \(url) - \(d)")
                }
            } else {
                print("reponse has no data: \(String(describing: response))")
            }
        }

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let completeOp = BlockOperation {
            if errors.isEmpty {
                complete(rawData, nil)
            } else {
                complete([:], errors)
            }
        }

        let operations = queries.flatMap { (query) -> BlockOperation? in
            if query.command == Sun.sol.naifId {
                return nil
            }
            return BlockOperation {
                let task = URLSession.shared.dataTask(with: query.url, completionHandler: taskComplete)
                task.resume()
            }
        }

        // Add dependency to previous operation for each operation
        operations.enumerated().forEach { (index, op) in
            if index == 0 { return }
            op.addDependency(operations[index - 1])
            completeOp.addDependency(op)
        }

        queue.addOperations(operations + [completeOp], waitUntilFinished: false)
    }

    public func fetchOnlineRawDataExponentialBackoff(queries: [HorizonsQuery], complete: @escaping ([Int: String], [Error]?) -> Void) {
        var tasksTrialCount: [URL: Int] = [:]
        var rawData: [Int: String] = [:]
        var errors: [Error] = []

        // load online data
        let group = DispatchGroup()
        func taskComplete(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
            defer {
                group.leave()
            }

            // exponential back off retry
            func retry(url: URL) -> Bool {
                let trialCount = tasksTrialCount[url] ?? 0
                guard trialCount < trialCountLimit else {
                    return false
                }
                let timeInterval: TimeInterval = trialBackoffTimeInterval * (pow(2.0, Double(trialCount)))
                tasksTrialCount[url] = trialCount + 1
                group.enter()
                DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) {
                    let retryUrl = url
                    let retryTask = URLSession.shared.dataTask(with: retryUrl, completionHandler: taskComplete)
                    retryTask.resume()
                }
                return true
            }
            let nsError = error as NSError?
            if let e = nsError {
                if !retry(url: e.userInfo[NSURLErrorFailingURLErrorKey] as! URL) {
                    errors.append(e)
                }
            } else if let d = data {
                let httpResponse = response as! HTTPURLResponse
                let url = httpResponse.url!
                let utf8String = String(data: d, encoding: .utf8)!
                switch ResponseValidator.default.parse(content: utf8String) {
                case .busy:
                    print("busy: \(url), retrying")
                    let retried = retry(url: url)
                    if retried == false {
                        // retries run out
                        print("stop retrying: \(url)")
                    }
                default:
                    rawData[url.naifId!] = utf8String
                    print("complete: \(url) - \(d)")
                }
            } else {
                print("reponse has no data: \(String(describing: response))")
            }
        }
        let tasks = queries.flatMap { (query) -> URLSessionTask? in
            if query.command == Sun.sol.naifId {
                return nil
            }
            return URLSession.shared.dataTask(with: query.url, completionHandler: taskComplete)
        }
        tasks.enumerated().forEach { (index: Int, task: URLSessionTask) in
            group.enter()
            let timeInterval: TimeInterval = timeIntervalBetweenJobs * Double(index)
            DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) {
                task.resume()
            }
        }
        group.notify(queue: .main) {
            defer {
                tasksTrialCount.removeAll()
                errors.removeAll()
                rawData.removeAll()
            }
            guard errors.isEmpty else {
                print("complete with failure: fetching celestial bodies")
                complete([:], errors)
                return
            }
            print("complete: fetching celestial bodies")
            complete(rawData, nil)
        }
    }

    /// Fetch ephemeris of major bodies and moons
    ///
    /// - Parameters:
    ///   - preferredDate: The preferred date of ephemeris
    ///   - offline: When set to `true`, return immediately if local data is available and do not attempt to fetch online
    ///   - update: Called when planet data is ready; may never be called or be called multiple times
    ///   - complete: Block to execute upon completion
    public func fetchEphemeris(preferredDate: Date = Date(), naifs: [Naif] = [Naif.sun] + Naif.motionDefault, mode: FetchMode = .mixed, update: ((Ephemeris) -> Void)? = nil, complete: ((Ephemeris?, [Error]?) -> Void)? = nil) {
        // load local data
        var cachedBodies = Set<CelestialBody>(mode == .onlineOnly ? [] : (naifs.flatMap {
            CelestialBody.load(naifId: $0.rawValue)
        }))
        if cachedBodies.isEmpty && mode == .localOnly {
            complete?(nil, nil)
            return
        }
        if cachedBodies.isEmpty == false {
            if naifs.contains(Naif.sun) {
                cachedBodies.insert(Sun.sol)
            }
            update?(Ephemeris(solarSystemBodies: cachedBodies))
            if mode == .preferLocal || mode == .localOnly {
                complete?(Ephemeris(solarSystemBodies: cachedBodies), nil)
                return
            }
        }
        let queries = HorizonsQuery.ephemerisQuery(naifs, date: preferredDate)
        fetchOnlineRawData(queries: queries) { (rawData, errors) in
            if let errors = errors {
                if cachedBodies.isEmpty {
                    complete?(nil, errors)
                } else {
                    let eph = Ephemeris(solarSystemBodies: cachedBodies)
                    complete?(eph, errors)
                }
                return
            }
            var bodies = Set<CelestialBody>(rawData.flatMap { (_, content) -> CelestialBody? in
                if let body = CelestialBodyParser.default.parse(content: content) {
                    body.save()
                    return body
                }
                return nil
            })
            if naifs.contains(Naif.sun) && bodies.first(where: { $0.naif == Naif.sun }) == nil {
                bodies.insert(Sun.sol)
            }
            let merged = self.mergeCelestialBodies(cachedBodies, bodies, refTime: preferredDate)
            let eph = Ephemeris(solarSystemBodies: merged)
            update?(eph)
            complete?(eph, nil)
        }
    }

    public func fetchRiseTransitSetElevation(preferredDate: Date = Date(), observerSite site: ObserverSite, naifs: [Naif] = Naif.observerDefault, mode: FetchMode = .preferLocal, update: (([Naif: RiseTransitSetElevation]) -> Void)? = nil, complete: (([Naif: RiseTransitSetElevation], [Error]?) -> Void)? = nil) {
        // load local data
        let rtseList: [RiseTransitSetElevation] = (mode == .onlineOnly ? [] : naifs.flatMap {
            RiseTransitSetElevation.load(naifId: $0.rawValue, optimalJulianDate: JulianDate(date: preferredDate))
        })
        var rtseDict = [Naif: RiseTransitSetElevation]()
        rtseList.forEach { rtseDict[$0.naif] = $0 }
        let isComplete = naifs.map { rtseDict[$0] != nil }.reduce(true, { $0 && $1 })
        if isComplete {
            update?(rtseDict)
        }
        if mode == .localOnly || (mode == .preferLocal && isComplete) {
            complete?(rtseDict, nil)
            return
        }
        let queries = HorizonsQuery.rtsQueries(naifs: Set<Naif>(naifs), site: site, date: preferredDate)
        fetchOnlineRawData(queries: queries) { (rawData, errors) in
            if let errors = errors {
                if isComplete == false {
                    complete?([:], errors)
                } else {
                    complete?(rtseDict, errors)
                }
                return
            }
            rawData.forEach { (_, content) in
                let rts = ObserverRiseTransitSetParser.default.parse(content: content)
                rts.save()
            }
            naifs.forEach { naif in
                let rtse = RiseTransitSetElevation.load(naifId: naif.rawValue, optimalJulianDate: JulianDate(date: preferredDate))!
                rtseDict[naif] = rtse
            }
            update?(rtseDict)
            complete?(rtseDict, nil)
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
