//
//  Line.swift
//  Graviton
//
//  Created by Ben Lu on 4/26/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

fileprivate struct LineMode {
    enum Fill {
        case solid
        case dashed
    }

    let fill: Fill
    let closes: Bool

    var indexGenerator: (Int) -> [CInt] {
        let final: (Int) -> Int = closes ? { $0 } : { $0 - 1 }
        switch fill {
        case .solid:
            return { index -> [CInt] in (0...final(index)).map { CInt($0 % index) } }
        case .dashed:
            return { index -> [CInt] in (0...final(index)).map { CInt($0 % index) } }
        }
    }
}

extension SCNGeometry {
    static func polyLine(vertices: [SCNVector3], solid: Bool, closes: Bool) -> SCNGeometry {
        let numberOfVertices = vertices.count
        let mode = LineMode(fill: solid ? .solid : .dashed, closes: closes)
        let indices = mode.indexGenerator(numberOfVertices)
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
}
