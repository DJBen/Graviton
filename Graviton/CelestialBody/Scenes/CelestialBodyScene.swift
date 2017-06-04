//
//  CelestialBodyScene.swift
//  Graviton
//
//  Created by Sihao Lu on 5/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits
import SpaceTime
import MathUtil

class CelestialBodyScene: SCNScene, CameraResponsive {
    static let defaultFov: Double = 30

    private lazy var camera: SCNCamera = {
        let c = SCNCamera()
        c.automaticallyAdjustsZRange = true
        c.xFov = defaultFov
        c.yFov = defaultFov
        return c
    }()

    lazy var cameraNode: SCNNode = {
        let cn = SCNNode()
        cn.camera = self.camera
        return cn
    }()

    var gestureOrientation: Quaternion {
        return Quaternion.identity
    }

    lazy var solarNode: SCNNode = {
        let light = SCNLight()
        light.type = .directional
        light.castsShadow = true
        let node = SCNNode()
        node.light = light
        return node
    }()

    lazy var celestialNode = CelestialBodyNode(naif: .moon(.luna))

    var scale: Double = 1

    func resetCamera() {
        cameraNode.position = SCNVector3()
        cameraNode.pivot = SCNMatrix4MakeTranslation(0, 0, -5)
        cameraNode.rotation = SCNVector4()
    }

    override init() {
        super.init()
        rootNode.addChildNode(cameraNode)
        resetCamera()
        rootNode.addChildNode(celestialNode)
        celestialNode.addChildNode(solarNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Observer Update
    func updateObserverInfo(_ observerInfo: [Naif: CelestialBodyObserverInfo]) {
        if let moonInfo = observerInfo[.moon(.luna)] {
            solarNode.light!.intensity = 1500
            let eq = EquatorialCoordinate(
                rightAscension: radians(degrees: moonInfo.npRa),
                declination: radians(degrees: moonInfo.npDec),
                distance: 1
            )
            let northPoleAxis = Vector3(equatorialCoordinate: eq)
            precondition(northPoleAxis.length ~= 1, "North pole axis should be normalized")
            let rotation = Quaternion.init(alignVector: Vector3(0, 1, 0), with: northPoleAxis)
            let latRot = Quaternion.init(axisAngle: Vector4(0, 0, 1, -radians(degrees: moonInfo.obLon)))
            celestialNode.orientation = SCNQuaternion(latRot * rotation)
            celestialNode.pivot = SCNMatrix4(Matrix4.init(rotation: Vector4(1, 0, 0, Double.pi / 2)))
            let slXRot = -radians(degrees: moonInfo.slLat.value!)
            let slYRot = radians(degrees: moonInfo.slLon.value!)
            var slMat = Matrix4(rotation: Vector4(1, 0, 0, slXRot))
            slMat = slMat * Matrix4(rotation: Vector4(0, 1, 0, slYRot))
            solarNode.transform = SCNMatrix4(slMat)
        } else {
            // solarNode.light!.intensity = 1500
        }
        print(observerInfo)
    }

    func updateRiseTransitSetInfo(_ rtsInfo: [Naif: RiseTransitSetElevation]) {
        print(rtsInfo)
    }
}
