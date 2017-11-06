//
//  ObserveTarget.swift
//  Graviton
//
//  Created by Sihao Lu on 11/5/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Orbits
import StarryNight

enum ObserveTarget: CustomStringConvertible {
    case star(Star)
    case nearbyBody(Body)

    var description: String {
        switch self {
        case let .star(star):
            return String(describing: star.identity)
        case let .nearbyBody(nb):
            return nb.name
        }
    }
}
