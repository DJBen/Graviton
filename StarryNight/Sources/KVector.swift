//
//  KVector.swift
//  StarryNight
//
//  Created by Jatin Mathur on 7/13/23.
//

import Foundation

/// Enables efficient retrieval of data when data is roughly linearly distributed, with performance that can far-exceed that of binary search
/// For more information, see "A k-Vector Approach to Sampling, Interpolation, and Approximation" by Mortari et al.
public class KVector<T> {
    let data: [(Double, T)]
    let kVector: [Int]
    let m: Double
    let q: Double
    
    init(data: inout [(Double, T)]) {
        data.sort { $0.0 < $1.0 }
        self.data = data
        let min = data[0].0
        let max = data[data.count - 1].0
        let n = data.count
        var kVector = Array(repeating: 0, count: data.count)
        kVector[n - 1] = n - 1
        let eps: Double = 1e-10
        self.m = (max - min + 2*eps)/Double(n - 1)
        self.q = min - self.m - eps
        
        var dataIdx = 0
        for i in 1..<data.count-1 {
            while self.m * Double(i) + self.q >= data[dataIdx].0 {
                dataIdx += 1
            }
            
            if dataIdx > 0 {
                kVector[i] = dataIdx - 1
            }
        }
        self.kVector = kVector
    }
    
    public func getData(lower: Double, upper: Double) -> ArraySlice<(Double,T)> {
        assert(lower <= upper)
        if lower > self.data[self.data.count - 1].0 || upper < self.data[0].0 {
            return ArraySlice<(Double,T)>([])
        }
        
        var jl = 0
        if lower > self.data[0].0 {
            jl = Int(floor((lower - self.q) / self.m))
        }
        
        var ju = self.data.count - 1
        if upper < self.data[self.data.count - 1].0 {
            ju = Int(ceil((upper - self.q) / self.m))
        }
        
        let kstart = self.kVector[jl]
        let kend = self.kVector[ju]
        
        // TODO: delete
//        let dataSlice = Array(self.data[kstart...kend])
//        // Search for the lower index
//        var (idxL, lowerIdx, _) = binarySearch(in: dataSlice, for: lower)
//        if idxL != nil {
//            // We found the index, meaning the value exists. Hence, lower is the current index
//            lowerIdx = idxL!
//        }
//
//        // Search for the upper index
//        var (idxU, _, upperIdx) = binarySearch(in: dataSlice, for: upper)
//        if idxU != nil {
//            upperIdx = idxU!
//        }
//        return dataSlice[lowerIdx...upperIdx]
        
        var start: Int? = nil
        var end: Int? = nil
        for i in kstart...kend {
            if start == nil && self.data[i].0 > lower {
                start = i
            }
            
            if end == nil && self.data[i].0 > upper {
                end = i - 1
            }
        }
        
        let sstart = start ?? kstart
        let send = end ?? kend
        return self.data[sstart...send]
    }
}
