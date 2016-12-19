//
//  Telneter.swift
//  Graviton
//
//  Created by Ben Lu on 11/27/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation

class Telneter {
    let address: InternetAddress
    let timeout: DispatchTimeInterval
    var textReceived: String = ""
    var matchStart: Int = 0
    var newTextBlock: ((String) -> Void)?
    var timeoutBlock: ((Telneter, String) -> Void)?
    var defaultBlock: ((String) -> String)?
    var successBlock: ((Telneter, String) -> Void)?
    var onceRepliers = [(keyword: String, reply: (String) -> String)]()
    var autoRepliers = [(keyword: String, reply: (String) -> String)]()
    var matchers = [(regex: NSRegularExpression, matched: (String, [NSTextCheckingResult]) -> Void)]()
    var semaphore: DispatchSemaphore?
    var stopSignal: String?
    var stopper: ((String) -> Bool)?
    
    init(address: InternetAddress, timeout: DispatchTimeInterval) {
        self.address = address
        self.timeout = timeout
    }
    
    private func autoReply(with client: TCPClient, using repliers: inout [(keyword: String, reply: (String) -> String)], shouldConsume: Bool, currentText: String, fullText: String) throws -> Bool {
        for i in 0..<repliers.count {
            let (keyword, reply) = repliers[i]
            if currentText.contains(keyword) {
                try client.send(bytes: (reply(fullText) + "\r\n").toBytes())
                if shouldConsume {
                    repliers.remove(at: i)
                }
                return true
            }
        }
        return false
    }
    
    func printOnReceive() -> Telneter {
        newTextBlock = { print($0, separator: "", terminator: "") }
        return self
    }
    
    func onMatch(_ pattern: String, matched: @escaping (String, [NSTextCheckingResult]) -> Void) -> Telneter {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        matchers.append((regex: regex, matched: matched))
        return self
    }
    
    func stop(with command: String? = nil, when stopper: @escaping (String) -> Bool) -> Telneter {
        self.stopSignal = command
        self.stopper = stopper
        return self
    }
    
    func signalStop() {
        semaphore?.signal()
    }
    
    func performStopProcedure(client: TCPClient) throws {
        guard client.socket.closed == false else {
            return
        }
        if let signal = self.stopSignal{
            try client.send(bytes: (signal + "\r\n").toBytes())
        }
        try client.close()
    }
    
    func start() {
        semaphore = DispatchSemaphore(value: 0)
        var client: TCPClient!
        DispatchQueue.global(qos: .utility).async {
            do {
                client = try TCPClient(address: self.address)
                while true {
                    do {
                        let string = try client.receiveAll().toString()
                        self.newTextBlock?(string)
                        let fullText = self.textReceived.appending(string)
                        if let s = self.stopper, s(fullText) {
                            try self.performStopProcedure(client: client)
                            self.signalStop()
                            break
                        }
                        for (regex, matchCallback) in self.matchers {
                            let matches = regex.matches(in: fullText, options: [], range: NSRange(location: self.matchStart, length: fullText.characters.count - self.matchStart))
                            if let lastMatch = matches.last {
                                self.matchStart = lastMatch.range.location + lastMatch.range.length
                            }
                            guard matches.isEmpty == false else {
                                continue
                            }
                            matchCallback(fullText, matches)
                        }
                        let found = try self.autoReply(with: client, using: &self.onceRepliers, shouldConsume: true, currentText: string, fullText: fullText)
                        if !found {
                            let autoFound = try self.autoReply(with: client, using: &self.autoRepliers, shouldConsume: false, currentText: string, fullText: fullText)
                            if let fallbackText = self.defaultBlock?(fullText), !autoFound {
                                try client.send(bytes: (fallbackText + "\r\n").toBytes())
                            }
                        }
                        self.textReceived = fullText
                    } catch let e as SocksError {
                        if e.number != SocksError(.unparsableBytes).number {
                            // ignore invalid bytes not others
                            throw e
                        }
                    }
                }
            } catch {
                print("Error \(error)")
            }
        }

        let result = semaphore!.wait(timeout: DispatchTime.now() + timeout)
        if result == .timedOut {
            do {
                try self.performStopProcedure(client: client)
            } catch { print("Error \(error)") }
            timeoutBlock?(self, textReceived)
        } else {
            successBlock?(self, textReceived)
        }
    }
    
    func reply(to keyword: String, reply: @escaping (String) -> String) -> Telneter {
        autoRepliers.append((keyword: keyword, reply: reply))
        return self
    }
    
    /// Reply to a keyword once. This method has higher priority than `reply(to:reply:)`
    ///
    /// - parameter keyword: keyword
    /// - parameter reply:   a reply block containing the full text that returns the reply
    ///
    /// - returns: self
    func replyOnce(to keyword: String, reply: @escaping (String) -> String) -> Telneter {
        onceRepliers.append((keyword: keyword, reply: reply))
        return self
    }
    
    func returnOnce(on keyword: String) -> Telneter {
        onceRepliers.append((keyword: keyword, reply: { _ in "\r"}))
        return self
    }
    
    func timedOut(_ timeoutBlock: @escaping (Telneter, String) -> Void) -> Telneter {
        self.timeoutBlock = timeoutBlock
        return self
    }
    
    func succeeded(_ successBlock: @escaping (Telneter, String) -> Void) -> Telneter {
        self.successBlock = successBlock
        return self
    }
    
    func `default`(_ defaultBlock: @escaping (String) -> String) -> Telneter {
        self.defaultBlock = defaultBlock
        return self
    }
}

extension InternetAddress {
    func open(for duration: DispatchTimeInterval = DispatchTimeInterval.seconds(60)) -> Telneter {
        let listener = Telneter(address: self, timeout: duration)
        return listener
    }
}

fileprivate extension String {
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
