//
//  KelvinColor.swift
//  KelvinColor
//
//  Created by Sihao Lu on 8/24/17.
//  Copyright © 2017 Sihao. All rights reserved.
//

// Ported from https://raw.githubusercontent.com/neilbartlett/color-temperature/master/index.js

import Foundation
import UIKit

public extension UIColor {
    /// Initialize color based on the Kelvin temperature
    ///
    /// - Parameter kelvin: color temperature in degrees Kelvin
    convenience init(temperature kelvin: Double) {
        let temperature = kelvin / 100.0
        var red, green, blue: Double

        if (temperature < 66.0) {
            red = 255
        } else {
            // a + b x + c Log[x] /.
            // {a -> 351.97690566805693`,
            // b -> 0.114206453784165`,
            // c -> -40.25366309332127
            //x -> (kelvin/100) - 55}
            red = temperature - 55.0
            red = 351.97690566805693 + 0.114206453784165 * red - 40.25366309332127 * log(red)
            if red < 0 {
                red = 0
            }
            if red > 255 {
                red = 255
            }
        }

        if (temperature < 66.0) {
            // a + b x + c Log[x] /.
            // {a -> -155.25485562709179`,
            // b -> -0.44596950469579133`,
            // c -> 104.49216199393888`,
            // x -> (kelvin/100) - 2}
            green = temperature - 2
            green = -155.25485562709179 - 0.44596950469579133 * green + 104.49216199393888 * log(green)
            if green < 0 {
                green = 0
            }
            if green > 255 {
                green = 255
            }
        } else {
            // a + b x + c Log[x] /.
            // {a -> 325.4494125711974`,
            // b -> 0.07943456536662342`,
            // c -> -28.0852963507957`,
            // x -> (kelvin/100) - 50}
            green = temperature - 50.0
            green = 325.4494125711974 + 0.07943456536662342 * green - 28.0852963507957 * log(green)
            if green < 0 {
                green = 0
            }
            if green > 255 {
                green = 255
            }

        }

        if (temperature >= 66.0) {
            blue = 255
        } else {
            if (temperature <= 20.0) {
                blue = 0
            } else {
                // a + b x + c Log[x] /.
                // {a -> -254.76935184120902`,
                // b -> 0.8274096064007395`,
                // c -> 115.67994401066147`,
                // x -> kelvin/100 - 10}
                blue = temperature - 10
                blue = -254.76935184120902 + 0.8274096064007395 * blue + 115.67994401066147 * log(blue)
                if blue < 0 {
                    blue = 0
                }
                if blue > 255 {
                    blue = 255
                }
            }
        }

        self.init(red: CGFloat(red / 255.0), green: CGFloat(green / 255.0), blue: CGFloat(blue / 255.0), alpha: 1)
    }

    var temperature: Double {
        var temperature: Double = 0
        var testRGB: UIColor
        let epsilon: Double = 0.4
        var minTemperature: Double = 1000
        var maxTemperature: Double = 40000
        while (maxTemperature - minTemperature > epsilon) {
            temperature = (maxTemperature + minTemperature) / 2
            testRGB = UIColor.init(temperature: temperature)
            var testBlue: CGFloat = 0
            var testRed: CGFloat = 0
            testRGB.getRed(&testRed, green: nil, blue: &testBlue, alpha: nil)
            var currentBlue: CGFloat = 0
            var currentRed: CGFloat = 0
            self.getRed(&currentRed, green: nil, blue: &currentBlue, alpha: nil)
            if testBlue / testRed >= currentBlue / currentRed {
                maxTemperature = temperature
            } else {
                minTemperature = temperature
            }
        }
        return round(temperature)
    }
}
