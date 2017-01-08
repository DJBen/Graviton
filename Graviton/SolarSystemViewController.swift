//
//  SolarSystemViewController.swift
//  Graviton
//
//  Created by Ben Lu on 9/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits
import SpaceTime

let rawEphermeris = ["499": "2457660.500000000, A.D. 2016-Sep-29 00:00:00.0000,  9.349691790268522E-02,  2.066309874915549E+08,  1.848383279439611E+00,  4.950714593925647E+01,  2.866750747652687E+02,  2.457691051476427E+06,  6.065118217885201E-06,  3.439902254751289E+02,  3.406654208788684E+02,  2.279429508540520E+08,  2.492549142165491E+08,  5.935580924678589E+07,\r\n", "599": "2457660.500000000, A.D. 2016-Sep-29 00:00:00.0000,  4.903681021765440E-02,  7.399766936971012E+08,  1.303726503031742E+00,  1.005116966413447E+02,  2.737960651650042E+02,  2.455636851003679E+06,  9.620643806225045E-07,  1.682104854162316E+02,  1.692933954560466E+02,  7.781338979760779E+08,  8.162911022550546E+08,  3.741953316752687E+08,\r\n", "699": "2457660.500000000, A.D. 2016-Sep-29 00:00:00.0000,  5.255722218855435E-02,  1.355587765421777E+09,  2.484816633636572E+00,  1.136286166649233E+02,  3.405375583707204E+02,  2.452849202337529E+06,  3.857256575984343E-07,  1.603446584911329E+02,  1.622518030186439E+02,  1.430785897754300E+09,  1.505984030086823E+09,  9.333058169928215E+08,\r\n", "899": "2457660.500000000, A.D. 2016-Sep-29 00:00:00.0000,  6.733346296082503E-03,  4.457307450814839E+09,  1.775109814929700E+00,  1.318699872348611E+02,  2.865897132979180E+02,  2.470519731376491E+06,  6.943517414332845E-08,  2.828549113940708E+02,  2.821012758644750E+02,  4.487523500555891E+09,  4.517739550296943E+09,  5.184692116662458E+09,\r\n", "199": "2457660.500000000, A.D. 2016-Sep-29 00:00:00.0000,  2.056269278803274E-01,  4.600141281053489E+07,  7.003986365751242E+00,  4.830945064624417E+01,  2.917155359696631E+01,  2.457660141199273E+06,  4.736510465859539E-05,  1.468336375450634E+00,  2.276964516836183E+00,  5.790907877552620E+07,  6.981674474051753E+07,  7.600532134254884E+06,\r\n", "399": "2457660.500000000, A.D. 2016-Sep-29 00:00:00.0000,  1.648960814331977E-02,  1.472482201056044E+08,  4.271760807118733E-03,  1.792277746806384E+02,  2.810527397582937E+02,  2.457754304819286E+06,  1.139390123314296E-05,  2.676554340935340E+02,  2.657693773221828E+02,  1.497169946802777E+08,  1.521857692549510E+08,  3.159585050226871E+07,\r\n", "299": "2457660.500000000, A.D. 2016-Sep-29 00:00:00.0000,  6.747565752194679E-03,  1.074776560089246E+08,  3.394403982272081E+00,  7.663370646657754E+01,  5.501591478050264E+01,  2.457580507517262E+06,  1.854347652050164E-05,  1.281604658806697E+02,  1.287652675053035E+02,  1.082077952220857E+08,  1.089379344352467E+08,  1.941383535077603E+07,\r\n", "799": "2457660.500000000, A.D. 2016-Sep-29 00:00:00.0000,  4.982886173843559E-02,  2.719763247093349E+09,  7.715398487449768E-01,  7.401596674902862E+01,  9.834876928092277E+01,  2.470172858293421E+06,  1.362994269933934E-07,  2.126510842409861E+02,  2.097254879908949E+02,  2.862393033816450E+09,  3.005022820539551E+09,  2.641243679017446E+09,\r\n", "999": "2457755.500000000, A.D. 2017-Jan-02 00:00:00.0000,  2.509498346851184E-01,  4.409102175404617E+09,  1.724057938952910E+01,  1.102730881369775E+02,  1.122306888210467E+02,  2.447609289136021E+06,  4.621889545612947E-08,  4.051699135471582E+01,  6.423941429033752E+01,  5.886257529295309E+09,  7.363412883186001E+09,  7.789022140126835E+09,\r\n", "2000001": "2457660.500000000, A.D. 2016-Sep-29 00:00:00.0000,  7.568862259906738E-02,  3.827602138611231E+08,  1.059186940246066E+01,  8.031249941717938E+01,  7.283653875366169E+01,  2.458235656865199E+06,  2.476941302486429E-06,  2.369119857276488E+02,  2.300193209004539E+02,  4.141031076966779E+08,  4.454460015322328E+08,  1.453405454697780E+08,\r\n"]

class SolarSystemViewController: SceneControlViewController {

//    var system = solarSystem
    
    lazy var ephemeris = EphemerisParser.parse(list: rawEphermeris)!
    
    var lastRenderTime: TimeInterval!
    var timeElapsed: TimeInterval = 0
    var refTime: Date!
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    lazy var solScene: SolScene = {
        let scene = SolScene()
        self.fillSolScene(scene)
        return scene
    }()
    
    private func fillSolScene(_ scene: SolScene) {
        scene.clear()
        scene.addOrbitalMotion(motion: self.ephemeris.motion(of: "199")!, color: #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1), identifier: "mercury")
        scene.addOrbitalMotion(motion: self.ephemeris.motion(of: "299")!, color: #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1), identifier: "venus")
        scene.addOrbitalMotion(motion: self.ephemeris.motion(of: "399")!, color: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), identifier: "earth")
        scene.addOrbitalMotion(motion: self.ephemeris.motion(of: "499")!, color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1), identifier: "mars")
        scene.addOrbitalMotion(motion: self.ephemeris.motion(of: "599")!, color: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1), identifier: "jupiter")
        scene.addOrbitalMotion(motion: self.ephemeris.motion(of: "699")!, color: #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1), identifier: "saturn")
        scene.addOrbitalMotion(motion: self.ephemeris.motion(of: "799")!, color: #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1), identifier: "uranus")
        scene.addOrbitalMotion(motion: self.ephemeris.motion(of: "899")!, color: #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), identifier: "neptune")
        scene.addOrbitalMotion(motion: self.ephemeris.motion(of: "999")!, color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1), identifier: "pluto")
//        scene.addOrbit(orbit: self.ephemeris.orbit(of: "2000001")!, color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1), identifier: "ceres")
    }
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var warpControl: WarpControl = {
        let control = WarpControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
  
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
        refTime = Date()
        cameraController = solScene
//        Horizons().fetchPlanets { (ephemeris, errors) in
//            guard errors == nil else {
//                print(errors!)
//                return
//            }
//            self.ephemeris = ephemeris!
//            self.fillSolScene(self.solScene)
//        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    private func setupViewElements() {
        let scnView = self.view as! SCNView
        scnView.addSubview(timeLabel)
        scnView.addConstraints(
            [
                timeLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 14),
                timeLabel.rightAnchor.constraint(equalTo: scnView.rightAnchor, constant: -16)
            ]
        )
        scnView.addSubview(warpControl)
        scnView.addConstraints(
            [
                warpControl.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 8),
                warpControl.leftAnchor.constraint(equalTo: scnView.leftAnchor, constant: 16)
            ]
        )
        scnView.delegate = self
        scnView.scene = solScene
        scnView.isPlaying = true
        scnView.backgroundColor = UIColor.black
    }
    
    // MARK: - Scene Renderer Delegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if lastRenderTime == nil {
            lastRenderTime = time
        }
        let dt: TimeInterval = time - lastRenderTime
        lastRenderTime = time
        let warpedDeltaTime = dt * warpControl.speed.multiplier
        timeElapsed += warpedDeltaTime
        let warpedDate = Date(timeInterval: timeElapsed, since: refTime)
        let warpedJd = JulianDate(date: warpedDate).value
        self.solScene.julianDate = Float(warpedJd)
        let actualTime = self.refTime.addingTimeInterval(TimeInterval(timeElapsed))
        DispatchQueue.main.async {
            self.timeLabel.text = self.dateFormatter.string(from: actualTime)
        }
    }
}


