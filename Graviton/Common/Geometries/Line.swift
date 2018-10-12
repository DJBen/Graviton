//
//  Line.swift
//  Graviton
//
//  Created by Ben Lu on 4/26/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import MathUtil
import SceneKit
import UIKit

private struct LineMode {
    enum Fill {
        case solid
        case dashed
    }

    let fill: Fill
    let closes: Bool

    var generateIndex: (Int) -> [CInt] {
        let final: (Int) -> Int = closes ? { $0 } : { $0 - 1 }
        switch fill {
        case .solid:
            return { index -> [CInt] in (0 ... final(index)).map { CInt($0 % index) } }
        case .dashed:
            return { index -> [CInt] in (0 ... final(index)).map { CInt($0 % index) } }
        }
    }
}

extension SCNGeometry {
    static func polyLine(vertices: [SCNVector3], solid: Bool, closes: Bool) -> SCNGeometry {
        let numberOfVertices = vertices.count
        let mode = LineMode(fill: solid ? .solid : .dashed, closes: closes)
        let indices = mode.generateIndex(numberOfVertices)
        let geometrySources = [SCNGeometrySource(vertices: vertices)]
        let geometryElements = [SCNGeometryElement(indices: indices, primitiveType: .line)]
        return SCNGeometry(sources: geometrySources, elements: geometryElements)
    }

    static func openSolidPolyLine(vertices: [SCNVector3]) -> SCNGeometry {
        return polyLine(vertices: vertices, solid: true, closes: false)
    }

    static func closedDashedPolyLine(vertices: [SCNVector3]) -> SCNGeometry {
        return polyLine(vertices: vertices, solid: false, closes: true)
    }

    static func dottedLine(vertices: [SCNVector3]) -> SCNGeometry {
        func generateIndex(_ numberOfSegments: Int) -> [CInt] {
            return (0 ... (numberOfSegments * 2)).map { CInt($0 % (numberOfSegments * 2)) }
        }
        func extendVertices(_ vertices: [SCNVector3]) -> [SCNVector3] {
            let diffs = vertices.enumerated().map { (index, vertex) -> SCNVector3 in
                let nextIndex = index == vertices.count - 1 ? 0 : index + 1
                let nextVertex = vertices[nextIndex]
                return nextVertex - vertex
            }
            return vertices.enumerated().flatMap { (enumeration) -> [SCNVector3] in
                let (index, vertex) = enumeration
                return [vertex, vertex + diffs[index].normalized() * 0.02]
            }
        }
        let finalVertices = extendVertices(vertices)
        let finalIndices = generateIndex(vertices.count)
        let geometrySources = [SCNGeometrySource(vertices: finalVertices)]
        let geometryElements = [SCNGeometryElement(indices: finalIndices, primitiveType: .line)]
        return SCNGeometry(sources: geometrySources, elements: geometryElements)
    }
}
