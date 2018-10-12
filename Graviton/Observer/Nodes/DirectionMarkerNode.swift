//
//  DirectionMarkerNode.swift
//  Graviton
//
//  Created by Ben Lu on 6/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation
import MathUtil
import SceneKit
import SpaceTime
import UIKit

extension ObserverScene {
    class DirectionMarkerNode: BooleanFlaggedNode {
        enum Marker {
            case east
            case west
            case north
            case south

            var unitPosition: Vector3 {
                switch self {
                case .north:
                    return Vector3(1, 0, 0)
                case .south:
                    return Vector3(-1, 0, 0)
                case .east:
                    return Vector3(0, 1, 0)
                case .west:
                    return Vector3(0, -1, 0)
                }
            }

            var transparentTexture: UIImage {
                switch self {
                case .north:
                    return #imageLiteral(resourceName: "direction_marker_north")
                case .south:
                    return #imageLiteral(resourceName: "direction_marker_south")
                case .east:
                    return #imageLiteral(resourceName: "direction_marker_east")
                case .west:
                    return #imageLiteral(resourceName: "direction_marker_west")
                }
            }

            func markerTransform(pitch: Double, yaw: Double, roll: Double) -> Quaternion {
                switch self {
                case .north:
                    return Quaternion(pitch: 0, yaw: 0, roll: Double.pi / 2) * Quaternion(pitch: 0, yaw: yaw, roll: roll)
                case .west:
                    return .identity * Quaternion(pitch: pitch, yaw: 0, roll: roll)
                case .south:
                    return Quaternion(pitch: 0, yaw: 0, roll: -Double.pi / 2) * Quaternion(pitch: 0, yaw: yaw, roll: roll)
                case .east:
                    return Quaternion(pitch: 0, yaw: Double.pi, roll: 0) * Quaternion(pitch: pitch, yaw: 0, roll: roll)
                }
            }
        }

        private class MarkerNode: SCNNode {
            let marker: Marker

            init(marker: Marker) {
                self.marker = marker
                super.init()
            }

            required init?(coder _: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }

        let radius: Double
        let sideLength: Double

        var observerLocationTime: ObserverLocationTime = ObserverLocationTime() {
            didSet {
                let ecefToNed = Quaternion(rotationMatrix: observerLocationTime.localViewTransform)
                childNodes.forEach { node in
                    let markerNode = node as! MarkerNode
                    node.position = SCNVector3(ecefToNed * markerNode.marker.unitPosition * radius)
                    var orientation = Quaternion(lookAt: Vector3.zero, from: Vector3(node.position))
                    let (pitch, yaw, roll) = (ecefToNed.inverse * orientation).toPitchYawRoll()
                    orientation = ecefToNed * markerNode.marker.markerTransform(pitch: pitch, yaw: yaw, roll: roll)
                    node.orientation = SCNQuaternion(orientation)
                }
            }
        }

        init(radius: Double, sideLength: Double) {
            self.radius = radius
            self.sideLength = sideLength
            super.init(setting: .showDirectionMarkers)
            name = "direction marker"
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setUpMarker(_ marker: Marker) {
            let plane = SCNPlane(width: CGFloat(sideLength), height: CGFloat(sideLength))
            plane.firstMaterial?.isDoubleSided = true
            plane.firstMaterial?.transparent.contents = marker.transparentTexture
            plane.firstMaterial?.diffuse.contents = #colorLiteral(red: 0.9241236663, green: 0.9842761147, blue: 1, alpha: 1)
            let node = MarkerNode(marker: marker)
            node.geometry = plane
            node.position = SCNVector3(marker.unitPosition * radius)
            addChildNode(node)
        }

        // MARK: - ObserverSceneElement

        override var isSetUp: Bool {
            return childNodes.count > 0
        }

        override func setUpElement() {
            setUpMarker(.north)
            setUpMarker(.south)
            setUpMarker(.east)
            setUpMarker(.west)
        }

        override func removeElement() {
            childNodes.forEach { $0.removeFromParentNode() }
        }

        override func hideElement() {
            childNodes.forEach { $0.isHidden = true }
        }

        override func showElement() {
            childNodes.forEach { node in
                node.isHidden = false
            }
        }
    }
}
