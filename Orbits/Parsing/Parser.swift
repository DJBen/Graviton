//
//  Parser.swift
//  Graviton
//
//  Created by Ben Lu on 3/24/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

public protocol Parser {
    associatedtype Result
    
    static var `default`: Self { get }
    
    func parse(content: String) -> Result
}
