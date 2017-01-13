//
//  Horizons.swift
//  StarCatalog
//
//  Created by Sihao Lu on 12/20/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation

// Example request
// http://ssd.jpl.nasa.gov/horizons_batch.cgi?batch=1&CENTER='SUN'&COMMAND='399'&MAKE_EPHEM='YES'%20&TABLE_TYPE='elements'&START_TIME='2000-10-01'&STOP_TIME='2000-12-31'&STEP_SIZE='15%20d'%20%20%20%20&QUANTITIES='1,9,20,23,24'&CSV_FORMAT='YES'

class Horizons {
    static let batchUrl = "http://ssd.jpl.nasa.gov/horizons_batch.cgi"
    static let trialCountLimit = 3
    // back off time should be the following value * pow(CONSTANT, numberOfTrials)
    // usually CONSTANT = 2
    static let trialBackoffTimeInterval: TimeInterval = 0.5
    static let timeIntervalBetweenJobs: TimeInterval = 0.2
    
    private var tasksTrialCount: [URL: Int] = [:]
    private var rawEphemeris: [Int: String] = [:]
    
    private var errors: [Error] = []
    
    func fetchPlanets(complete: ((Ephemeris?, [Error]?) -> Void)? = nil) {
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
                    self.rawEphemeris[url.naifId!] = utf8String
                    print("complete: \(url) - \(d)")
                }
            } else {
                print("reponse has no data: \(response)")
            }
        }
        let tasks = HorizonsQuery.planetQueryItems.map { (query) -> URLSessionTask in
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
                self.rawEphemeris.removeAll()
            }
            guard self.errors.isEmpty else {
                print("complete with failure: fetching planets")
                complete?(nil, self.errors)
                return
            }
            print("complete: fetching planets")
            let bodies = Array(self.rawEphemeris).map { (naif, content) -> CelestialBody in
                let motion = ResponseParser.parseEphemeris(content: content)
                let body = CelestialBody(naifId: naif, mass: 0, radius: 0)
                body.motion = motion
                return body
            }
            let ephemeris = Ephemeris(celestialBodies: bodies)
            complete?(ephemeris, nil)
        }
    }
}

enum NaifBody {
    enum MajorBody: String {
        case sun = "10"
        case mercury = "199"
        case venus = "299"
        case earth = "399"
        case mars = "499"
        case jupiter = "599"
        case saturn = "699"
        case uranus = "799"
        case neptune = "899"
    }
    
    case majorBody(MajorBody)
    
    static let planets: [NaifBody] = {
        let planets: [MajorBody] = [.mercury, .venus, .earth, .mars, .jupiter, .saturn, .uranus, .neptune]
        return planets.map { .majorBody($0) }
    }()
    
    var rawValue: String {
        switch self {
        case let .majorBody(mb):
            return mb.rawValue
        }
    }
}

// CENTER = 'SUN'
// COMMAND = '399'
// MAKE_EPHEM = 'YES'
// TABLE_TYPE = 'elements'
// START_TIME = '2000-10-01'
// STOP_TIME = '2000-12-31'
// STEP_SIZE = '15d'
// CSV_FORMAT = 'YES'

struct HorizonsQuery: Hashable {
    enum TableType: String {
        case elements
        case observers
        case vectors
        case approach
    }
    
    enum StepSize: Equatable {
        case day(Int)
        case hour(Int)
        case minute(Int)
        case step(Int)
        
        var rawValue: String {
            switch self {
            case let .day(d):
                return "\(d) days"
            case let .hour(h):
                return "\(h) hours"
            case let .minute(m):
                return "\(m) min"
            case let .step(s):
                return "\(s)"
            }
        }
        
        public static func ==(lhs: StepSize, rhs: StepSize) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }
    
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MMM-dd HH:mm"
        return formatter
    }()
    
    var hashValue: Int {
        return command.hashValue ^ startTime.hashValue ^ stopTime.hashValue ^ stepSize.rawValue.hashValue
    }
    
    var center: String?
    var command: String
    var shouldMakeEphemeris: Bool = true
    var tableType: TableType
    var startTime: Date
    var stopTime: Date
    var useCsvFormat: Bool = true
    var stepSize: StepSize = .step(1)
    
    var queryItems: [URLQueryItem] {
        var mappings: [String: String] = [
            "batch": "1",
            "MAKE_EPHEM": shouldMakeEphemeris.yesNo,
            "TABLE_TYPE": tableType.rawValue.capitalized,
            "COMMAND": command,
            "START_TIME": HorizonsQuery.formatter.string(from: startTime),
            "STOP_TIME": HorizonsQuery.formatter.string(from: stopTime),
            "CSV_FORMAT": useCsvFormat.yesNo,
            "STEP_SIZE": stepSize.rawValue
        ]
        if let c = center {
            mappings["CENTER"] = c
        }
        return mappings.map { (key, value) -> URLQueryItem in
            return URLQueryItem(name: key, value: value.quoteWrapped)
        }
    }
    
    var url: URL {
        let urlComponent = NSURLComponents(string: Horizons.batchUrl)!
        urlComponent.queryItems = queryItems
        return urlComponent.url!
    }
    
    static let planetQueryItems: [HorizonsQuery] = {
        return NaifBody.planets.map { (planet) -> HorizonsQuery in
            return HorizonsQuery(center: NaifBody.MajorBody.sun.rawValue, command: planet.rawValue, shouldMakeEphemeris: true, tableType: .elements, startTime: Date(), stopTime: Date(timeIntervalSinceNow: 3600), useCsvFormat: true, stepSize: StepSize.step(1))
        }
    }()
    
    public static func ==(lhs: HorizonsQuery, rhs: HorizonsQuery) -> Bool {
        return lhs.command == rhs.command && lhs.startTime == rhs.startTime && lhs.stopTime == rhs.stopTime && lhs.useCsvFormat == rhs.useCsvFormat && lhs.center == rhs.center && lhs.shouldMakeEphemeris == rhs.shouldMakeEphemeris && lhs.stepSize == rhs.stepSize && lhs.tableType == rhs.tableType
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

fileprivate extension Bool {
    var yesNo: String {
        return self ? "YES" : "NO"
    }
}

fileprivate extension String {
    var quoteWrapped: String {
        return "'\(self)'"
    }
}
