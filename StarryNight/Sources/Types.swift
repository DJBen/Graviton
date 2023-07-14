//
//  File.swift
//  
//
//  Created by Jatin Mathur on 7/14/23.
//

import Foundation

public class DeterministicSet<Element: Hashable>: Sequence {
    // These should be references to the element, so the duplication to
    // achieve determinisim should not be bad
    private var array: [Element] = []
    private var set: Set<Element> = []

    var count: Int { return array.count }

    public func append(_ element: Element) {
        if set.insert(element).inserted {
            array.append(element)
        }
    }

    public func contains(_ element: Element) -> Bool {
        return set.contains(element)
    }

    public func intersection(_ other: DeterministicSet<Element>) -> DeterministicSet<Element> {
        let newSet: DeterministicSet<Element> = DeterministicSet()
        for e in array.filter { other.contains($0) } {
            newSet.append(e)
        }
        return newSet
    }

    public func arrayRepresentation() -> [Element] {
        return array
    }
    
    public func makeIterator() -> IndexingIterator<[Element]> {
        return array.makeIterator()
    }
}
