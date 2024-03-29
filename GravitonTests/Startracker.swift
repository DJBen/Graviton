//
//  Startracker.swift
//  GravitonTests
//
//  Created by Jatin Mathur on 7/19/23.
//

import XCTest
@testable import StarryNight
import SpaceTime
import LASwift

class StartrackerTest: XCTestCase {
    /// Copied from StarryNight Startracker test, but meant to run on a phone. This helps us understand runtime on an actual phone.
    /// Remember to keep this in-sync.
    func testNotEnoughStars0() {
        let path = Bundle.module.path(forResource: "not_enough_stars_0", ofType: "png")!
        XCTAssertNotNil(path, "Image not found")
        let image = UIImage(contentsOfFile: path)!
        let st = StarTracker()
        let focalLength = 2863.6363
        let T_Ceq_Meq = try! st.track(image: image, focalLength: focalLength, maxStarCombos: MAX_STAR_COMBOS).get()

        // (hr, u, v)
        let bigDipperStars = [
            (5191, 341.11764705882354, 1797.4705882352941),
            (5054, 406.0, 2176.0285714285715),
            (4905, 273.16129032258067,  2399.6129032258063),
            (4660, 155.06896551724137, 3357.67241379310333),
            (4301, 155.06896551724137, 3357.6724137931033)
        ]

        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        let pix2ray = Pix2Ray(focalLength: focalLength, cx: Double(width) / 2, cy: Double(height) / 2)
        let intrinsics = inv(pix2ray.intrinsics_inv)
        var reprojErr = 0.0
        for (hr, u, v) in bigDipperStars {
            let s = Star.hr(hr)!
            let rotStar = (T_Cc_Ceq * T_Ceq_Meq.T * s.physicalInfo.coordinate.toMatrix()).toVector3()
            XCTAssertTrue(rotStar.z > 0)
            var rotStarScaled = rotStar.toMatrix()
            // TODO: I can't seem to import MathUtil here so I am doing this instead of doing
            // what is happening in the corresponding test case in the StarryNight package
            rotStarScaled[0,0] = rotStarScaled[0,0]/rotStarScaled[2,0]
            rotStarScaled[1,0] = rotStarScaled[1,0]/rotStarScaled[2,0]
            rotStarScaled[2,0] = rotStarScaled[2,0]/rotStarScaled[2,0]
            let projUV = (intrinsics * rotStarScaled).toVector3()
            let err = sqrt(pow(projUV.x - u, 2) + pow(projUV.y - v, 2))
            reprojErr += err
        }
        let avgReprojErr = reprojErr / Double(bigDipperStars.count)
        print("Average Big Dipper Reprojection Error: \(avgReprojErr)")
        XCTAssertTrue(avgReprojErr < 250)
    }
}
