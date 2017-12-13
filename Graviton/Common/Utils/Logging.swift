//
//  Logging.swift
//  Graviton
//
//  Created by Sihao Lu on 2/7/18.
//  Copyright © 2018 Ben Lu. All rights reserved.
//

import SwiftyBeaver

let logger = SwiftyBeaver.self

func configureLogging() {
    let console = ConsoleDestination()
    console.minLevel = .verbose
    logger.addDestination(console)
}
