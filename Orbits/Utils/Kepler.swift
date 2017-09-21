//
//  Kepler.swift
//  Orbits
//
//  Created by Ben Lu on 11/19/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

// Cited from http://www.projectpluto.com/kepler.htm

/* If the eccentricity is very close to parabolic,  and the eccentric
 anomaly is quite low,  you can get an unfortunate situation where
 roundoff error keeps you from converging.  Consider the just-barely-
 elliptical case,  where in Kepler's equation,

 M = E - e sin(E)

 E and e sin(E) can be almost identical quantities.  To
 around this,  nearParabolic() computes E - e sin(E) by expanding
 the sine function as a power series:

 E - e sin(E) = E - e(E - E^3/3! + E^5/5! - ...)
 = (1-e)E + e(-E^3/3! + E^5/5! - ...)

 It's a little bit expensive to do this,  and you only need do it
 quite rarely.  (I only encountered the problem because I had orbits
 that were supposed to be 'pure parabolic',  but due to roundoff,
 they had e = 1+/- epsilon,  with epsilon _very_ small.)  So 'nearParabolic'
 is only called if we've gone seven iterations without converging. */

import Foundation

private let minThresh: Double = 1.0e-15
private let startThresh: Double = 1.0e-12
private let maxIterations: Int = 7

private func cubeRoot(_ x: Double) -> Double {
    return exp(log(x) / 3.0)
}

private func nearParabolic(eccAnom: Double, e: Double) -> Double {
    let anom2: Double = (e > 1.0 ? eccAnom * eccAnom : -eccAnom * eccAnom)
    var term: Double = e * anom2 * eccAnom / 6.0
    var rval: Double = (1.0 - e) * eccAnom - term
    var n = 4

    while fabs(term) > 1e-15 {
        term *= anom2 / Double(n * (n + 1))
        rval -= term
        n += 2
    }
    return(rval)
}

public func solveInverseKepler(eccentricity ecc: Float, meanAnomaly ma: Float) -> Float {
    return Float(solveInverseKepler(eccentricity: Double(ecc), meanAnomaly: Double(ma)))
}

public func solveInverseKepler(eccentricity ecc: Double, meanAnomaly ma: Double) -> Double {
    var curr: Double = 0
    var err: Double = 0
    var thresh: Double = 0
    var offset: Double = 0
    var deltaCurr: Double = 1
    var isNegative: Bool = false
    var nIter: Int = 0
    var meanAnom: Double = ma

    if meanAnom == 0 {
        return 0
    }

    if ecc < 1.0 {
        if meanAnom < -Double.pi || meanAnom > Double.pi {
            var tmod: Double = fmod(meanAnom, Double.pi * 2.0)

            if tmod > Double.pi { /* bring mean anom within -pi to +pi */
                tmod -= 2.0 * Double.pi
            } else if tmod < -Double.pi {
                tmod += 2.0 * Double.pi
            }
            offset = meanAnom - tmod
            meanAnom = tmod
        }

        if ecc < 0.99999 {    /* low-eccentricity formula from Meeus,  p. 195 */
            curr = atan2(sin(meanAnom), cos(meanAnom) - ecc)
            repeat {
                err = (curr - ecc * sin(curr) - meanAnom) / (1.0 - ecc * cos(curr))
                curr -= err
            } while fabs(err) > startThresh
            return curr + offset
        }
    }

    if meanAnom < 0 {
        meanAnom = -meanAnom
        isNegative = true
    }

    curr = meanAnom
    thresh = startThresh * fabs(1.0 - ecc)

    /* Due to roundoff error,  there's no way we can hope to */
    /* get below a certain minimum threshhold anyway:        */
    if thresh < minThresh {
        thresh = minThresh
    } else if thresh > startThresh {       /* i.e.,  ecc > 2. */
        thresh = startThresh
    }

    if meanAnom < Double.pi / 3.0 || ecc > 1.0 { /* up to 60 degrees */
        var trial: Double = meanAnom / fabs(1.0 - ecc)

        if trial * trial > 6.0 * fabs(1.0 - ecc) {   /* cubic term is dominant */
            if meanAnom < Double.pi {
                trial = cubeRoot(6.0 * meanAnom)
            } else {       /* hyperbolic w/ 5th & higher-order terms predominant */
                trial = asinh(meanAnom / ecc)
            }
        }
        curr = trial
    }
    if ecc < 1.0 {
        while fabs(deltaCurr) > thresh {
            if nIter > maxIterations {
                nIter += 1
                err = nearParabolic(eccAnom: curr, e: ecc) - meanAnom
            } else {
                nIter += 1
                err = curr - ecc * sin(curr) - meanAnom
                deltaCurr = -err / (1.0 - ecc * cos(curr))
                curr += deltaCurr
            }

        }
    } else {
        while fabs(deltaCurr) > thresh {
            if nIter > maxIterations {
                nIter += 1
                err = -nearParabolic(eccAnom: curr, e: ecc) - meanAnom
            } else {
                nIter += 1
                err = ecc * sinh(curr) - curr - meanAnom
                deltaCurr = -err / (ecc * cosh(curr) - 1.0)
                curr += deltaCurr
            }
        }
    }
    return isNegative ? offset - curr : offset + curr
}
