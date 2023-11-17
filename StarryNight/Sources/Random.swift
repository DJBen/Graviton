//
//  Random.swift
//  
//
//  Created by Jatin Mathur on 7/11/23.
//

import Foundation
import GameplayKit

class SeededGenerator: RandomNumberGenerator {
    let seed: UInt64
    private let generator: GKMersenneTwisterRandomSource
    
    init(seed: UInt64) {
        self.seed = seed
        generator = GKMersenneTwisterRandomSource(seed: seed)
    }
    
    func next() -> UInt64 {
        let nextUpperBits = UInt64(abs(self.generator.nextInt())) << 32
        let nextLowerBits = UInt64(abs(self.generator.nextInt()))
        return nextUpperBits | nextLowerBits
    }
    
    func nextInt(upper: Int?) -> Int {
        if upper == nil {
            return self.generator.nextInt()
        } else {
            return self.generator.nextInt(upperBound: upper!)
        }
    }
}
