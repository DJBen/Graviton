//
//  CompassRoseNode.swift
//  Graviton
//
//  Created by Ben Lu on 6/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import MathUtil
import CoreLocation

extension ObserverScene {
    class CompassRoseNode: BooleanFlaggedNode {

        let radius: Double
        let sideLength: Double

        /// The orientation to transform from ECEF to NED coordinate
        ///
        /// **Note**: do not use orientation property or the orientation of each marker will be wrong
        var ecefToNedOrientation: Quaternion = Quaternion.identity {
            didSet {
                updatePositionAndAttitude()
            }
        }

        init(radius: Double, sideLength: Double) {
            self.radius = radius
            self.sideLength = sideLength
            super.init(setting: .showZenithAndNadirMarkers)
            name = "direction marker"
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private var zenithNode: SCNNode {
            return childNode(withName: "zenith", recursively: false)!
        }

        private var nadirNode: SCNNode {
            return childNode(withName: "nadir", recursively: false)!
        }

        private func setUpMarker(isZenith: Bool) {
            let plane = SCNPlane(width: CGFloat(sideLength), height: CGFloat(sideLength))
            plane.firstMaterial?.isDoubleSided = true
            plane.firstMaterial?.diffuse.contents = #colorLiteral(red: 0.9241236663, green: 0.9842761147, blue: 1, alpha: 1)
            let node = SCNNode(geometry: plane)
            if isZenith {
                node.name = "zenith"
                plane.firstMaterial?.transparent.contents = #imageLiteral(resourceName: "texture_compass_rose_zenith")
            } else {
                node.name = "nadir"
                plane.firstMaterial?.transparent.contents = #imageLiteral(resourceName: "texture_compass_rose_nadir")
                plane.firstMaterial?.transparent.contentsTransform = {
                    var mtx = SCNMatrix4MakeTranslation(-0.5, -0.5, 0)
                    mtx = SCNMatrix4Rotate(mtx, Float(Double.pi), 0, 0, 1)
                    mtx = SCNMatrix4Translate(mtx, 0.5, 0.5, 0)
                    return mtx
                }()
            }
            node.geometry = plane
            node.position = SCNVector3(Vector3(0, 0, isZenith ? -1 : 1) * radius)
            addChildNode(node)
        }

        func updatePositionAndAttitude() {
            zenithNode.position = SCNVector3(self.ecefToNedOrientation * Vector3(0, 0, -1) * radius)
            zenithNode.orientation = SCNQuaternion(self.ecefToNedOrientation * Quaternion(axisAngle: Vector4(0, 0, 1, -Double.pi / 2)))
            nadirNode.position = SCNVector3(self.ecefToNedOrientation * Vector3(0, 0, 1) * radius)
            nadirNode.orientation = SCNQuaternion(self.ecefToNedOrientation * Quaternion(axisAngle: Vector4(1, 0, 0, Double.pi)) * Quaternion(axisAngle: Vector4(0, 0, 1, Double.pi / 2)))
        }

        // MARK: - ObserverSceneElement

        override var isSetUp: Bool {
            return childNodes.count > 0
        }

        override func setUpElement() {
            setUpMarker(isZenith: true)
            setUpMarker(isZenith: false)
        }

        override func removeElement() {
            childNodes.forEach { $0.removeFromParentNode() }
        }

        override func hideElement() {
            childNodes.forEach { $0.isHidden = true }
        }

        override func showElement() {
            updatePositionAndAttitude()
            childNodes.forEach { node in
                node.isHidden = false
            }
        }
    }
}
