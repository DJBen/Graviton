//
//  Kepler.swift
//  Graviton
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
 around this,  near_parabolic() computes E - e sin(E) by expanding
 the sine function as a power series:
 
 E - e sin(E) = E - e(E - E^3/3! + E^5/5! - ...)
 = (1-e)E + e(-E^3/3! + E^5/5! - ...)
 
 It's a little bit expensive to do this,  and you only need do it
 quite rarely.  (I only encountered the problem because I had orbits
 that were supposed to be 'pure parabolic',  but due to roundoff,
 they had e = 1+/- epsilon,  with epsilon _very_ small.)  So 'near_parabolic'
 is only called if we've gone seven iterations without converging. */

import Foundation

fileprivate let PI: Double = 3.1415926535897932384626433832795028841971693993751058209749445923
fileprivate let MIN_THRESH: Double = 1.0e-15
fileprivate let THRESH: Double = 1.0e-12
fileprivate let MAX_ITERATIONS: Int = 7

fileprivate func cubeRoot(_ x: Double) -> Double {
    return exp(log(x) / 3.0)
}

fileprivate func nearParabolic(ecc_anom: Double, e: Double) -> Double
{
    let anom2: Double = (e > 1.0 ? ecc_anom * ecc_anom : -ecc_anom * ecc_anom)
    var term: Double = e * anom2 * ecc_anom / 6.0
    var rval: Double = (1.0 - e) * ecc_anom - term
    var n = 4
    
    while(fabs(term) > 1e-15)
    {
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
    var delta_curr: Double = 1
    var is_negative: Bool = false
    var n_iter: Int = 0
    var mean_anom: Double = ma
    
    if mean_anom == 0 {
        return 0
    }
    
    if ecc < 1.0 {
        if mean_anom < -PI || mean_anom > PI
        {
            var tmod: Double = fmod(mean_anom, PI * 2.0)
            
            if tmod > PI { /* bring mean anom within -pi to +pi */
                tmod -= 2.0 * PI
            }

            else if tmod < -PI {
                tmod += 2.0 * PI
            }
            offset = mean_anom - tmod
            mean_anom = tmod
        }
        
        if ecc < 0.99999 {    /* low-eccentricity formula from Meeus,  p. 195 */
            curr = atan2(sin(mean_anom), cos(mean_anom) - ecc)
            repeat {
                err = (curr - ecc * sin(curr) - mean_anom) / (1.0 - ecc * cos(curr))
                curr -= err
            } while fabs(err) > THRESH
            return curr + offset
        }
    }
    
    
    if mean_anom < 0
    {
        mean_anom = -mean_anom
        is_negative = true
    }
    
    curr = mean_anom
    thresh = THRESH * fabs(1.0 - ecc)
    
    /* Due to roundoff error,  there's no way we can hope to */
    /* get below a certain minimum threshhold anyway:        */
    if thresh < MIN_THRESH {
        thresh = MIN_THRESH
    } else if thresh > THRESH {       /* i.e.,  ecc > 2. */
        thresh = THRESH
    }
    
    if mean_anom < PI / 3.0 || ecc > 1.0 { /* up to 60 degrees */
        var trial: Double = mean_anom / fabs(1.0 - ecc)
        
        if trial * trial > 6.0 * fabs(1.0 - ecc) {   /* cubic term is dominant */
            if mean_anom < PI {
                trial = cubeRoot(6.0 * mean_anom)
            } else {       /* hyperbolic w/ 5th & higher-order terms predominant */
                trial = asinh(mean_anom / ecc)
            }
        }
        curr = trial
    }
    if ecc < 1.0 {
        while fabs(delta_curr) > thresh
        {
            if n_iter > MAX_ITERATIONS {
                n_iter += 1
                err = nearParabolic(ecc_anom: curr, e: ecc) - mean_anom
            } else {
                n_iter += 1
                err = curr - ecc * sin(curr) - mean_anom
                delta_curr = -err / (1.0 - ecc * cos(curr))
                curr += delta_curr
            }

        }
    } else {
        while fabs(delta_curr) > thresh
        {
            if n_iter > MAX_ITERATIONS {
                n_iter += 1
                err = -nearParabolic(ecc_anom: curr, e: ecc) - mean_anom
            } else {
                n_iter += 1
                err = ecc * sinh(curr) - curr - mean_anom
                delta_curr = -err / (ecc * cosh(curr) - 1.0)
                curr += delta_curr
            }
        }
    }
    return is_negative ? offset - curr : offset + curr
}
