//
//  ObserverScene.swift
//  Graviton
//
//  Created by Ben Lu on 2/4/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation
import MathUtil
import OpenGLES
import Orbits
import SceneKit
import SpaceTime
import StarryNight
import UIKit
import YinYang

private let milkywayLayerRadius: Double = 50
private let auxillaryLineLayerRadius: Double = 25
let auxillaryConstellationLabelLayerRadius: Double = 24
private let starLayerRadius: Double = 20
private let planetLayerRadius: Double = 10
private let landscapeLayerRadius: Double = 6
private let compassRoseRadius: Double = 5.5
private let directionMarkerLayerRadius: Double = 5.5
private let moonLayerRadius: Double = 7
private let sunLayerRadius: Double = 8
private let largeBodyScene = SCNScene(named: "art.scnassets/large_bodies.scn")!

class ObserverScene: SCNScene, CameraResponsive, FocusingSupport {
    struct VisibilityCategory: OptionSet {
        let rawValue: Int
        static let none = VisibilityCategory(rawValue: 0)
        /// All non-moon objects
        static let nonMoon = VisibilityCategory(rawValue: 1)
        /// The moon and its associated lighting
        static let moon = VisibilityCategory(rawValue: 1 << 1)
        /// Camera having the visibility of everything except none
        static let camera: VisibilityCategory = VisibilityCategory(rawValue: ~0)
    }

    static let defaultFov: Double = 70.29109 //50 // TODO: match camera FOV with code?
    /// Determines how fast zooming changes fov; the greater this number, the faster
    private static let fovExpBase: Double = 1.25
    private static let maxFov: Double = 120
    private static let minFov: Double = 8
    // scale is inverse proportional to fov
    private static let maxScale: Double = exp2(log(defaultFov / minFov) / log(fovExpBase))
    private static var minScale: Double = exp2(log(defaultFov / maxFov) / log(fovExpBase))

    /// Maximum magnification for the Sun and the Moon
    private static let maxMagnification: Double = 15

    var gestureOrientation: Quaternion = Quaternion.identity

    lazy var stars = Star.magitudeLessThan(Constants.Observer.maximumDisplayMagnitude)
    private var starMaterials: [String: SCNMaterial] = [:]

    private lazy var camera: SCNCamera = {
        let camera = SCNCamera()
        camera.zNear = 0.5
        camera.zFar = 1000
        camera.fieldOfView = CGFloat(ObserverScene.defaultFov)
        camera.projectionDirection = .horizontal
        camera.categoryBitMask = VisibilityCategory.camera.rawValue
        return camera
    }()

    lazy var cameraNode: SCNNode = {
        let cn = SCNNode()
        cn.camera = self.camera
        let quaternion = Quaternion(axisAngle: Vector4(0, 1, 0, Double.pi / 2)) * Quaternion(axisAngle: Vector4(1, 0, 0, -Double.pi / 2))
        cn.pivot = SCNMatrix4(Matrix4(quaternion: quaternion))
        return cn
    }()

    var focusedNode: SCNNode?

    var scale: Double = 1 {
        didSet {
            let cappedScale = min(max(scale, ObserverScene.minScale), ObserverScene.maxScale)
            scale = cappedScale
            camera.fieldOfView = CGFloat(fov)
            updateForZoomChanges()
        }
    }

    var fov: Double {
        get {
            return ObserverScene.defaultFov / pow(ObserverScene.fovExpBase, log2(scale))
        }
        set {
            guard fov > 0 else {
                fatalError("fov must be greater than 0")
            }
            let cappedFov = min(max(newValue, ObserverScene.minFov), ObserverScene.maxFov)
            scale = exp2(log(ObserverScene.defaultFov / cappedFov) / log(ObserverScene.fovExpBase))
        }
    }

    private var dynamicMagnificationFactor: Double {
        let easing = Easing(startValue: 1, endValue: ObserverScene.maxMagnification)
        let fovPercentage = (fov - ObserverScene.minFov) / (ObserverScene.maxFov - ObserverScene.minFov)
        return easing.value(at: fovPercentage)
    }

    // MARK: - Property - Visual Nodes

    private var celestialEquatorNode: CelestialEquatorLineNode?
    private var eclipticNode: EclipticLineNode?
    private var orbitLineNode: OrbitLineNode?
    private var meridianNode: MeridianLineNode?

    private lazy var milkyWayNode: SCNNode = {
        let node = SphereInteriorNode(radius: milkywayLayerRadius, textureLongitudeOffset: -Double.pi / 2)
        node.sphere.firstMaterial!.diffuse.contents = UIImage(named: "milkyway")
        node.sphere.firstMaterial!.locksAmbientWithDiffuse = true
        node.opacity = 0.3
        node.categoryBitMask = VisibilityCategory.nonMoon.rawValue
        return node
    }()

    lazy var panoramaNode: SCNNode = {
        let node = SphereInteriorNode(radius: landscapeLayerRadius)
        node.sphere.firstMaterial!.diffuse.contents = UIColor.white
        node.sphere.firstMaterial!.transparent.contents = UIImage(named: "debug_sphere_directions_transparency")
        node.sphere.firstMaterial!.transparent.contentsTransform = flipTextureContentsTransform
        node.sphere.firstMaterial!.isDoubleSided = true
        node.sphere.firstMaterial!.locksAmbientWithDiffuse = true
        node.categoryBitMask = VisibilityCategory.nonMoon.rawValue
        return node
    }()

    lazy var sunNode: SCNNode = {
        let sunMat = SCNMaterial()
        sunMat.diffuse.contents = #imageLiteral(resourceName: "sun")
        sunMat.locksAmbientWithDiffuse = true
        let sphere = SCNSphere(radius: 0.0)
        sphere.firstMaterial = sunMat
        let node = SCNNode(geometry: sphere)
        node.name = String(Sun.sol.naifId)
        node.categoryBitMask = VisibilityCategory.nonMoon.rawValue
        return node
    }()

    lazy var defaultLightingNode: SCNNode = {
        let light = SCNLight()
        light.type = .ambient
        light.intensity = 700
        light.categoryBitMask = VisibilityCategory.nonMoon.rawValue
        let node = SCNNode()
        node.light = light
        node.name = "default lighting"
        return node
    }()

    lazy var moonEarthshineNode: SCNNode = {
        let light = BooleanFlaggedLight(setting: .showEarthshine, on: { light in
            light.type = .omni
            light.categoryBitMask = VisibilityCategory.moon.rawValue
        }, off: { light in
            light.categoryBitMask = VisibilityCategory.none.rawValue
        })
        let node = SCNNode()
        node.light = light
        node.name = "earthshine"
        return node
    }()

    lazy var focuser: FocusIndicatorNode = {
        let focuser = FocusIndicatorNode(radius: 0.4)
        focuser.categoryBitMask = VisibilityCategory.nonMoon.rawValue
        return focuser
    }()

    lazy var moonLightingNode: SCNNode = {
        let light = BooleanFlaggedLight(setting: .showMoonPhase, on: { light in
            light.intensity = 1000
        }, off: { light in
            light.intensity = 0
        })
        light.type = .omni
        light.categoryBitMask = VisibilityCategory.moon.rawValue
        let node = SCNNode()
        node.light = light
        node.name = "moon lighting"
        return node
    }()

    lazy var moonFullLightingNode: SCNNode = {
        let light = BooleanFlaggedLight(setting: .showMoonPhase, on: { light in
            light.intensity = 0
        }, off: { light in
            light.intensity = 1000
        })
        light.type = .omni
        light.categoryBitMask = VisibilityCategory.moon.rawValue
        let node = SCNNode()
        node.light = light
        node.name = "moon full lighting"
        return node
    }()

    lazy var moonNode: SCNNode = {
        let moonMat = SCNMaterial()
        // material without normal is better in observer view
        moonMat.diffuse.contents = #imageLiteral(resourceName: "moon.jpg")
        moonMat.ambient.contents = UIColor.black
        moonMat.locksAmbientWithDiffuse = false
        // radius will be set later
        let sphere = SCNSphere(radius: 0.0)
        sphere.firstMaterial = moonMat
        let node = SCNNode(geometry: sphere)
        node.name = String(301)
        node.categoryBitMask = VisibilityCategory.moon.rawValue
        node.pivot = SCNMatrix4(
            Matrix4(rotation: Vector4(0, 1, 0, Double.pi / 2)) *
                Matrix4(rotation: Vector4(1, 0, 0, -Double.pi / 2))
        )
        return node
    }()

    lazy var compassRoseNode: CompassRoseNode = CompassRoseNode(radius: 5.5, sideLength: 0.8)

    lazy var directionMarkers = DirectionMarkerNode(radius: directionMarkerLayerRadius, sideLength: 0.3)
    var jumpToCelestialPointObserver: NSObjectProtocol!
    var jumpToDirectionObserver: NSObjectProtocol!

    // MARK: - View Life Cycle

    override init() {
        super.init()
        resetCamera()
        rootNode.addChildNode(defaultLightingNode)
        rootNode.addChildNode(milkyWayNode)
        rootNode.addChildNode(panoramaNode)
        rootNode.addChildNode(sunNode)
        rootNode.addChildNode(cameraNode)
        rootNode.addChildNode(directionMarkers)
        rootNode.addChildNode(compassRoseNode)
        glLineWidth(2)
        drawStars()
        drawConstellationLines()
        drawConstellationLabels()

        let southNode = IndicatorNode(setting: .showSouthPoleIndicator, position: SCNVector3(0, 0, -10), color: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1))
        southNode.name = "south pole indicator"
        rootNode.addChildNode(southNode)
        let northNode = IndicatorNode(setting: .showNorthPoleIndicator, position: SCNVector3(0, 0, 10), color: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1))
        northNode.name = "north pole indicator"
        rootNode.addChildNode(northNode)

        focuser.constraints = [SCNBillboardConstraint()]
        rootNode.addChildNode(focuser)
        focuser.isHidden = true

        jumpToCelestialPointObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "jumpToCelestialPoint"), object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let coordinate = notification.userInfo?["content"] as? EquatorialCoordinate else {
                return
            }
            self?.cameraNode.orientation = SCNQuaternion(Quaternion(alignVector: Vector3(1, 0, 0), with: Vector3(equatorialCoordinate: coordinate)))
        }
        jumpToDirectionObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "jumpToDirection"), object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let coordinate = notification.userInfo?["content"] as? HorizontalCoordinate else {
                return
            }
            guard let obInfo = ObserverLocationTimeManager.default.observerInfo else {
                logger.error("Missing observer info")
                return
            }
            self?.cameraNode.orientation = SCNQuaternion(Quaternion(alignVector: Vector3(1, 0, 0), with: Vector3(equatorialCoordinate: EquatorialCoordinate(horizontalCoordinate: coordinate, observerInfo: obInfo))))
        }

        loadPanoramaTexture(Settings.default[.groundTexture])
        Settings.default.subscribe(setting: .groundTexture, object: self) { [weak self] _, newValue in
            self?.loadPanoramaTexture(newValue)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(jumpToCelestialPointObserver)
        NotificationCenter.default.removeObserver(jumpToDirectionObserver)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Rendering Update

    private func updateForZoomChanges() {
        if let id = ephemerisSubscriptionIdentifier, let ephemeris = EphemerisManager.default.content(for: id) {
            updateDynamicSizes(forEphemeris: ephemeris)
        }
    }

    func rendererUpdate() {
        compassRoseNode.updateTransparency(withCameraOrientation: Quaternion(cameraNode.orientation))
    }

    // MARK: - Focusing support

    func resetCamera() {
        cameraNode.transform = SCNMatrix4Identity
        camera.fieldOfView = CGFloat(ObserverScene.defaultFov)
        scale = 1
    }

    func focus(atCelestialBody body: CelestialBody) {
        let node = rootNode.childNode(withName: String(body.naifId), recursively: true)!
        focus(atNode: node)
        if let id = ephemerisSubscriptionIdentifier, let ephemeris = EphemerisManager.default.content(for: id) {
            drawOrbitLine(celestialBody: body, ephemeris: ephemeris)
        }
    }

    func focus(atStar star: Star) {
        guard let node = rootNode.childNode(withName: String(star.identity.id), recursively: true) else {
            logger.warning("Cannot focus on star \(star.identity) because it is not rendered")
            return
        }
        focus(atNode: node)
        orbitLineNode?.removeFromParentNode()
        orbitLineNode = nil
    }

    func focus(atNode node: SCNNode) {
        focuser.isHidden = false
        focusedNode = node
        focuser.position = node.position.normalized() * 10
    }

    func removeFocus() {
        focuser.isHidden = true
        focusedNode = nil
        orbitLineNode?.removeFromParentNode()
        orbitLineNode = nil
    }

    // MARK: - Observer Update

    func observerInfoUpdate(observerInfo: [Naif: CelestialBodyObserverInfo]) {
        if observerInfo[.moon(.luna)] != nil {
            updateMoonOrientation()
        }
        logger.verbose(observerInfo)
    }

    private func updateMoonOrientation() {
        guard let moonInfo = CelestialBodyObserverInfoManager.default.content?[.moon(.luna)] else {
            return
        }
        let position = Vector3(moonNode.position)
        let moonEquatorialCoord = EquatorialCoordinate(cartesian: position)
        let obLonRad = RadianAngle(degreeAngle: DegreeAngle(moonInfo.obLon)).wrappedValue
        let obLatRad = RadianAngle(degreeAngle: DegreeAngle(moonInfo.obLat)).wrappedValue
        let moonPoleAxis = Vector3(equatorialCoordinate: EquatorialCoordinate(rightAscension: HourAngle(degreeAngle: DegreeAngle(moonInfo.npRa)), declination: DegreeAngle(moonInfo.npDec), distance: 1))
        let raRot = Quaternion(axisAngle: Vector4(0, 0, 1, RadianAngle(hourAngle: moonEquatorialCoord.rightAscension).wrappedValue - obLonRad))
        let decRotAxis = Vector3(position.x, -position.y, 0).normalized()
        let decRot = Quaternion(axisAngle: Vector4(decRotAxis, w: RadianAngle(degreeAngle: moonEquatorialCoord.declination).wrappedValue - obLatRad))
        let rotatedAxis = raRot * decRot * moonPoleAxis
        let parallanticAngleRot = Quaternion(alignVector: decRot * Vector3(0, 0, 1), with: rotatedAxis)
        let moonOrientation = parallanticAngleRot * raRot * decRot
        moonNode.orientation = SCNQuaternion(moonOrientation)
    }

    // MARK: - Location Update

    func updateLocation(location _: CLLocation) {
        guard let observerInfo = ObserverLocationTimeManager.default.observerInfo else {
            logger.debug("observer info not ready")
            return
        }
        updateStellarContent(observerInfo: observerInfo)
        drawMeridian(observerInfo: observerInfo)
    }

    /// Update content that should be updated upon ephemeris or time / location update,
    /// including but no limit to follows:
    /// - Compass rose
    /// - Direction markers
    /// - Ground texture
    /// - Meridian line (if enabled)
    func updateStellarContent(observerInfo: ObserverLocationTime) {
        let transform = observerInfo.localViewTransform
        let orientation = Quaternion(rotationMatrix: transform)
        logger.debug("update orientation \(orientation)")
        panoramaNode.orientation = SCNQuaternion(orientation)
        directionMarkers.observerLocationTime = observerInfo
        compassRoseNode.ecefToNedOrientation = orientation
        drawMeridian(observerInfo: observerInfo)
        // update focuser position
        if let focusedNode = self.focusedNode {
            focus(atNode: focusedNode)
        }
        if let eph = EphemerisManager.default.content(for: ephemerisSubscriptionIdentifier) {
            ephemerisDidUpdate(ephemeris: eph)
        }
        logger.debug("update location & time to \(observerInfo)")
    }

    // MARK: - Ephemeris Update

    func ephemerisDidLoad(ephemeris: Ephemeris) {
        drawAuxillaryLines(ephemeris: ephemeris)
        drawPlanetsAndMoon(ephemeris: ephemeris)
    }

    /// Called when ephemeris need recalculation due to change in time and / or observer location
    ///
    /// - Parameter ephemeris: Ephemeris to be recalculated
    private func ephemerisDidUpdate(ephemeris: Ephemeris) {
        let logMessage = "update ephemeris at \(String(describing: ephemeris.timestamp)) using data at \(String(describing: ephemeris.referenceTimestamp))"
        if Timekeeper.default.isWarpActive {
            logger.debug(logMessage)
        } else {
            logger.info(logMessage)
        }
        let earth = ephemeris[399]!
        let cbLabelNode = rootNode.childNode(withName: "celestialBodyAnnotations", recursively: false) ?? {
            let node = SCNNode()
            node.name = "celestialBodyAnnotations"
            rootNode.addChildNode(node)
            return node
        }()
        if earth.position == nil { return }
        let sunPos = -earth.position!
        // The should-be radius of the sun being displayed at a certain distance from camera
        let sunDisplaySize = Sun.sol.radius * sunLayerRadius / sunPos.length
        let zoomRatio = sunDisplaySize / Sun.sol.radius
        (sunNode.geometry as! SCNSphere).radius = CGFloat(sunDisplaySize * dynamicMagnificationFactor)
        let obliquedSunPos = sunPos.oblique(by: earth.obliquity)
        let sunDisplayPosition = obliquedSunPos * zoomRatio
        precondition(sunDisplayPosition.length ~= sunLayerRadius)
        sunNode.position = SCNVector3(sunDisplayPosition)
        sunNode.constraints = [SCNBillboardConstraint()]
        let earthPos = earth.position!
        annotateCelestialBody(Sun.sol, position: SCNVector3(obliquedSunPos), parent: cbLabelNode, class: .sunAndMoon)
        ephemeris.forEach { body in
            switch body.naif {
            case let .majorBody(mb):
                switch mb {
                case .earth: break
                default:
                    let planetRelativePos = (body.position! - earthPos).oblique(by: earth.obliquity)
                    if let planetNode = rootNode.childNode(withName: String(body.naifId), recursively: false) {
                        let position = SCNVector3(planetRelativePos.normalized() * planetLayerRadius)
                        planetNode.position = position
                        planetNode.constraints = [SCNBillboardConstraint()]
                        annotateCelestialBody(body, position: position, parent: cbLabelNode, class: .planet)
                    }
                }
            case let .moon(m):
                if m == Naif.Moon.luna {
                    guard let moonNode = rootNode.childNode(withName: String(m.rawValue), recursively: false) else { break }
                    let moonEclipticCoord = LunaUtil.moonEclipticCoordinate(forJulianDay: ephemeris.timestamp!)
                    var moonEquatorialCoord = EquatorialCoordinate(EclipticCoordinate: moonEclipticCoord, julianDay: ephemeris.timestamp!)
                    moonEquatorialCoord = EquatorialCoordinate(rightAscension: moonEquatorialCoord.rightAscension, declination: moonEquatorialCoord.declination, distance: moonEquatorialCoord.distance * 1000)
                    let moonDisplaySize = body.radius * moonLayerRadius / moonEquatorialCoord.distance
                    let moonZoomRatio = moonDisplaySize / body.radius
                    (moonNode.geometry as! SCNSphere).radius = CGFloat(moonDisplaySize * dynamicMagnificationFactor)
                    let relativePos = Vector3(equatorialCoordinate: moonEquatorialCoord)
                    let moonPosition = relativePos * moonZoomRatio
                    precondition(moonPosition.length ~= moonLayerRadius)
                    annotateCelestialBody(body, position: SCNVector3(moonPosition), parent: cbLabelNode, class: .sunAndMoon)
                    moonNode.position = SCNVector3(moonPosition)
                    let hypotheticalSunPos = obliquedSunPos * moonZoomRatio / dynamicMagnificationFactor
                    moonLightingNode.position = SCNVector3(hypotheticalSunPos)
                    moonEarthshineNode.position = SCNVector3Zero
                    moonFullLightingNode.position = SCNVector3Zero
                    let cosAngle = hypotheticalSunPos.normalized().dot(-moonPosition.normalized())
                    moonEarthshineNode.light?.intensity = CGFloat(max(-cosAngle, 0) * 80)
                    updateMoonOrientation()
                }
            default:
                break
            }
        }
    }

    /// Display Sun and Moon as big as 5x
    ///
    /// - Parameter ephemeris: The current ephemeris
    private func updateDynamicSizes(forEphemeris ephemeris: Ephemeris) {
        if let earth = ephemeris[.majorBody(.earth)], let earthPos = earth.position {
            let sunPos = -earthPos
            let sunDisplaySize = Sun.sol.radius * sunLayerRadius / sunPos.length
            (sunNode.geometry as! SCNSphere).radius = CGFloat(sunDisplaySize * dynamicMagnificationFactor)
        }
        if let moonBody = ephemeris[.moon(.luna)], let relativePos = moonBody.motion?.position {
            let moonDisplaySize = moonBody.radius * moonLayerRadius / relativePos.length
            (moonNode.geometry as! SCNSphere).radius = CGFloat(moonDisplaySize * dynamicMagnificationFactor)
        }
    }
}

// MARK: Dynamic Content Drawing

private extension ObserverScene {
    private func drawConstellationLines() {
        let constellationLineNode = SCNNode()
        constellationLineNode.name = "constellation lines"
        rootNode.addChildNode(constellationLineNode)
        if Settings.default[.constellationLineMode] == .none { return }
        for con in Constellation.all {
            for line in con.connectionLines {
                var coord1 = line.star1.physicalInfo.coordinate.normalized() * starLayerRadius
                var coord2 = line.star2.physicalInfo.coordinate.normalized() * starLayerRadius
                let diff = coord2 - coord1
                coord1 = coord1 + diff * 0.05
                coord2 = coord2 - diff * 0.05
                let vertexSources = SCNGeometrySource(vertices: [coord1, coord2].map { SCNVector3($0) })
                let elements = SCNGeometryElement(indices: [CInt(0), CInt(1)], primitiveType: .line)
                let lineGeo = SCNGeometry(sources: [vertexSources], elements: [elements])
                let mat = SCNMaterial()
                mat.diffuse.contents = #colorLiteral(red: 0.7595454454, green: 0.89753443, blue: 0.859713316, alpha: 1).withAlphaComponent(0.3)
                mat.locksAmbientWithDiffuse = true
                lineGeo.firstMaterial = mat
                let lineNode = SCNNode(geometry: lineGeo)
                constellationLineNode.addChildNode(lineNode)
            }
        }
    }

    private func drawPlanetsAndMoon(ephemeris: Ephemeris) {
        ephemeris.forEach { body in
            guard rootNode.childNode(withName: String(body.naifId), recursively: false) == nil else { return }
            var diffuse: UIImage?
            switch body.naif {
            case let .majorBody(mb):
                switch mb {
                case .earth: return
                case .pluto:
                    diffuse = #imageLiteral(resourceName: "grey_planet_diffuse")
                case .mercury:
                    diffuse = #imageLiteral(resourceName: "orange_planet_diffuse")
                case .venus:
                    diffuse = #imageLiteral(resourceName: "yellow_planet_diffuse")
                case .jupiter:
                    diffuse = #imageLiteral(resourceName: "yellow_planet_diffuse")
                case .saturn:
                    diffuse = #imageLiteral(resourceName: "orange_planet_diffuse")
                case .mars:
                    diffuse = #imageLiteral(resourceName: "red_planet_diffuse")
                case .uranus:
                    diffuse = #imageLiteral(resourceName: "pale_blue_planet_diffuse")
                case .neptune:
                    diffuse = #imageLiteral(resourceName: "blue_planet_diffuse")
                }
                let planetNode = SCNNode(geometry: SCNPlane(width: 0.1, height: 0.1))
                planetNode.geometry?.firstMaterial?.isDoubleSided = true
                planetNode.geometry!.firstMaterial!.diffuse.contents = diffuse!
                planetNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
                planetNode.geometry!.firstMaterial!.transparent.contents = #imageLiteral(resourceName: "planet_transparent")
                planetNode.name = String(body.naifId)
                planetNode.categoryBitMask = VisibilityCategory.nonMoon.rawValue
                rootNode.addChildNode(planetNode)
            case let .moon(m):
                if m == Naif.Moon.luna, moonNode.parent == nil {
                    rootNode.addChildNode(moonNode)
                    rootNode.addChildNode(moonLightingNode)
                    rootNode.addChildNode(moonEarthshineNode)
                    rootNode.addChildNode(moonFullLightingNode)
                }
            default:
                break
            }
        }
    }

    private func drawEcliptic(earth: CelestialBody) {
        func transform(position: Vector3) -> Vector3 {
            let rotated = position.oblique(by: earth.obliquity)
            return rotated.normalized() * auxillaryLineLayerRadius
        }
        eclipticNode?.removeFromParentNode()
        eclipticNode = EclipticLineNode(earth: earth, rawToModelCoordinateTransform: transform)
        rootNode.addChildNode(eclipticNode!)
    }

    private func drawCelestialEquator(earth: CelestialBody) {
        func transform(position: Vector3) -> Vector3 {
            return position.normalized() * auxillaryLineLayerRadius
        }
        celestialEquatorNode?.removeFromParentNode()
        celestialEquatorNode = CelestialEquatorLineNode(earth: earth, rawToModelCoordinateTransform: transform)
        rootNode.addChildNode(celestialEquatorNode!)
    }

    private func drawMeridian(observerInfo: ObserverLocationTime) {
        func transform(position: Vector3) -> Vector3 {
            return position.normalized() * auxillaryLineLayerRadius
        }
        meridianNode?.removeFromParentNode()
        meridianNode = MeridianLineNode(observerInfo: observerInfo, rawToModelCoordinateTransform: transform)
        rootNode.addChildNode(meridianNode!)
    }

    private func drawAuxillaryLines(ephemeris: Ephemeris) {
        let earth = ephemeris[399]!
        drawEcliptic(earth: earth)
        drawCelestialEquator(earth: earth)
    }

    private func drawOrbitLine(celestialBody: CelestialBody, ephemeris: Ephemeris) {
        guard let earth = ephemeris[.majorBody(.earth)] else {
            return
        }
        if celestialBody == earth || celestialBody is Sun {
            orbitLineNode?.removeFromParentNode()
            orbitLineNode = nil
            return
        }
        orbitLineNode?.removeFromParentNode()
        let color: UIColor?
        switch celestialBody.naif {
        case let .majorBody(mb):
            switch mb {
            case .earth: return
            case .pluto:
                color = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            case .mercury:
                color = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            case .venus:
                color = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
            case .jupiter:
                color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
            case .saturn:
                color = #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1)
            case .mars:
                color = #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)
            case .uranus:
                color = #colorLiteral(red: 0.8926730752, green: 0.9946536422, blue: 1, alpha: 1)
            case .neptune:
                color = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
            }
        case let .moon(moon):
            switch moon {
            case .luna:
                color = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            default:
                color = nil
            }
        default:
            color = nil
        }
        guard let finalColor = color else {
            logger.warning("attempt to show orbit line for unregistered celestial body \(celestialBody.naif) - showing nothing")
            return
        }
        orbitLineNode = OrbitLineNode(celestialBody: celestialBody, origin: earth, ephemeris: ephemeris, color: finalColor, rawToModelCoordinateTransform: { $0.normalized() * auxillaryLineLayerRadius })
        rootNode.addChildNode(orbitLineNode!)
    }

    private func radiusForMagnitude(_ mag: Double, blendOutStart: Double = -0.5, blendOutEnd: Double = 5) -> CGFloat {
        let maxSize: Double = 0.28
        let minSize: Double = 0.01
        let linearEasing = Easing(startValue: maxSize, endValue: minSize)
        let progress = mag / (blendOutEnd - blendOutStart)
        return CGFloat(linearEasing.value(at: progress))
    }
}

// MARK: Static Content Drawing

private extension ObserverScene {
    private func material(forStar star: Star) -> SCNMaterial {
        let spect = star.physicalInfo.spectralType

        if let spect = spect {
            let index = "\(spect.type)\(spect.subType != nil ? String(format: "%.1f", spect.subType!) : String())V"
            if let mat = starMaterials[index] {
                return mat
            }
            let mat = SCNMaterial()
            mat.transparent.contents = #imageLiteral(resourceName: "star16x16")
            mat.locksAmbientWithDiffuse = true
            mat.diffuse.contents = UIColor(temperature: spect.temperature)
            mat.selfIllumination.contents = UIColor.gray
            starMaterials[index] = mat
            return mat
        } else {
            if let defaultMat = starMaterials["default"] {
                return defaultMat
            }
            let mat = SCNMaterial()
            mat.transparent.contents = #imageLiteral(resourceName: "star16x16")
            mat.locksAmbientWithDiffuse = true
            mat.diffuse.contents = UIColor.white
            mat.selfIllumination.contents = UIColor.gray
            starMaterials["default"] = mat
            return mat
        }
    }

    private func drawStars() {
        for star in stars {
            let radius = radiusForMagnitude(star.physicalInfo.apparentMagnitude)
            let plane = SCNPlane(width: radius, height: radius)
            plane.firstMaterial = material(forStar: star)
            let starNode = SCNNode(geometry: plane)
            let coord = star.physicalInfo.coordinate.normalized() * starLayerRadius
            starNode.position = SCNVector3(coord)
            starNode.orientation = SCNQuaternion(Quaternion(lookAt: Vector3.zero, from: Vector3(starNode.position)))
            starNode.name = String(star.identity.id)
            starNode.categoryBitMask = VisibilityCategory.nonMoon.rawValue
            rootNode.addChildNode(starNode)
        }
    }
}

// MARK: - Panorama Rendering

private extension ObserverScene {
    private func loadPanoramaTexture(_ key: String) {
        panoramaNode.isHidden = key == "none"
        let material = panoramaNode.geometry?.firstMaterial
        switch key {
        case "citySilhoulette":
            material?.transparencyMode = .aOne
            material?.transparent.contents = UIImage(named: "panorama_city_silhoulette")
            material?.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.3)
        case "debugNode":
            material?.transparencyMode = .aOne
            material?.transparent.contents = UIImage(named: "debug_sphere_directions_transparency")
            material?.diffuse.contents = UIColor.white
        case "silverMountain":
            material?.transparencyMode = .aOne
            material?.transparent.contents = UIImage(named: "mountain_panorama")
            material?.diffuse.contents = UIColor.white
        case "none":
            break
        default:
            fatalError("unrecognized groundTexture setting")
        }
    }
}

private extension ObserverScene {
    private enum AnnotationClass {
        case planet
        case star
        case sunAndMoon
    }

    private func drawConstellationLabels() {
        let conLabelNode = SCNNode()
        conLabelNode.name = "constellation labels"
        for constellation in Constellation.all {
            guard let c = constellation.displayCenter else { continue }
            let center = SCNVector3(c.normalized())
            let textNode = TrackingLabelNode(string: constellation.name, textStyle: TextStyle.constellationLabelTextStyle(fontSize: 1.1))
            textNode.categoryBitMask = VisibilityCategory.nonMoon.rawValue
            textNode.constraints = [SCNBillboardConstraint()]
            textNode.position = center * Float(auxillaryConstellationLabelLayerRadius)
            conLabelNode.addChildNode(textNode)
        }
        rootNode.addChildNode(conLabelNode)
    }

    private func annotateCelestialBody(_ body: CelestialBody, position: SCNVector3, parent: SCNNode, class: AnnotationClass) {
        func offset(class: AnnotationClass) -> CGVector {
            switch `class` {
            case .sunAndMoon:
                return CGVector(dx: 0, dy: -1.2)
            case .planet:
                return CGVector(dx: 0, dy: -0.6)
            default:
                return CGVector.zero
            }
        }
        if let node = parent.childNode(withName: String(body.naifId), recursively: false) {
            node.position = position.normalized() * Float(auxillaryConstellationLabelLayerRadius)
            node.constraints = [SCNBillboardConstraint()]
        } else {
            let fontSize: CGFloat
            let color: UIColor
            switch `class` {
            case .planet:
                fontSize = 0.9
                color = #colorLiteral(red: 0.9616846442, green: 0.930521369, blue: 0.8593300581, alpha: 1)
            case .star:
                fontSize = 1.0
                color = #colorLiteral(red: 0.8279239535, green: 0.9453579783, blue: 0.9584422708, alpha: 1)
            case .sunAndMoon:
                fontSize = 0.95
                color = #colorLiteral(red: 0.9517338872, green: 0.8350647092, blue: 0.8214485049, alpha: 1)
            }
            let node = TrackingLabelNode(string: body.name, textStyle: TextStyle.nearStellarBodyTextStyle(fontSize: fontSize, color: color), offset: offset(class: `class`))
            node.categoryBitMask = VisibilityCategory.nonMoon.rawValue
            node.fontColor = color
            node.name = String(body.naifId)
            node.position = position.normalized() * Float(auxillaryConstellationLabelLayerRadius)
            node.constraints = [SCNBillboardConstraint()]
            parent.addChildNode(node)
        }
    }
}
