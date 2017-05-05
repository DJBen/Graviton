//
//  ResponseValidator.swift
//  Graviton
//
//  Created by Ben Lu on 3/24/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

public struct ResponseValidator: Parser {
    public typealias Result = ResponseStatus

    public enum ResponseStatus {
        case ok(String)
        case busy
    }

    public static let `default` = ResponseValidator()

    public func parse(content: String) -> ResponseStatus {
        if content.contains("Blocked Concurrent Request") {
            return .busy
        } else {
            return .ok(content)
        }
    }
}
