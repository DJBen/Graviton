![Header image](https://github.com/DJBen/Graviton/raw/master/External%20Assets/G-Purple.png)

# Graviton :milky_way:

[![Language](https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat)](https://swift.org)
[![Build Status](https://travis-ci.com/DJBen/Graviton.svg?token=1KVrf6xTWoPqLKJBPuJ1&branch=master)](https://travis-ci.com/DJBen/Graviton)
[![codebeat badge](https://codebeat.co/badges/de61d36c-440a-4cc7-85cf-97379e08ef15)](https://codebeat.co/a/sihao-lu/projects/github-com-djben-graviton-master?maxAge=3600)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

- _Real-time night sky and solar system rendering._
- _Astronomy and celestial mechanics toolkit._
- _Native Apple technologies with Swift 4 and SceneKit._
----
## App
- [x] Real-time night sky rendering. Fully customizable. Totally hackable.
  - [x] Reading from GPS or inputing custom position to see a night sky in your location.
  - [x] Time warp - see what night sky is like at any time.
- [x] Real-time high accuracy solar system illustration. In scale.
- [x] Detailed celestial body information. Rise, transit and set information panel for :sunny:, :first_quarter_moon_with_face: and naked-eye planets.

## Screenshots

| Stellarium | Planets | Metadata | Celestial body |
| --- | --- | --- | --- |
| ![main](https://github.com/DJBen/Graviton/raw/master/External%20Assets/screenshot-main.png) | ![planets](https://github.com/DJBen/Graviton/raw/master/External%20Assets/screenshot-planet.png) | ![rts](https://github.com/DJBen/Graviton/raw/master/External%20Assets/screenshot-rts.png) | ![celestial-body](https://github.com/DJBen/Graviton/raw/master/External%20Assets/screenshot-celestial-body.png) |

## Getting Started

Xcode 14, iOS 16 is required. This app is built with Swift Package Manager, open `Graviton.xcodeproj`.

## Features
*The work is primarily done in the year of 2017 and 2018. It is frozen as of Jul 2023.*

### Stellarium
1. View the simulated night sky at your local position and local time. Find the constellations and solar system plants.
2. Time warp to any time in the past and future to view the predicted night sky.
3. Browse the celestial object catalog, search the desired celestial objects and inspect their physical properties.

### Planets
1. View the real-time solar system.
2. Goes forward in time to see the motion of heaven.

### Information
1. Astronomic properties including Julian date, LST offset and more.
2. Rise, transit and set time of the sun, the moon and all planets.

Two websites are planned to be built. One includes all documentation, the other is a shiny front page for maximum appeal.

This project is a monorepo that also contains multiple useful frameworks. See below section.

## Goals

> **Outdated**

This is an amateurish project by an amateur astronomer. As a lover of science and space exploration, there are a few long-term goals:

- A full-fledged open source stellarium software
- An educational astronomy app with science in mind
- (?) A space flight simulator that utilizes [patched conics approximation](https://en.wikipedia.org/wiki/Patched_conic_approximation).

## Copyright
This project is licensed under GPLv3.
If you have issues with any assets or resources in Graviton, please don't hesitate to reach out [DJBen](mailto:lsh32768@gmail.com).

# Frameworks
## Orbits
_High accuracy ephemeris query and orbital mechanics calculation framework._
- [x] Calculate [Keplarian](https://en.wikipedia.org/wiki/Kepler_orbit) orbital mechanics with support of all [conics](https://en.wikipedia.org/wiki/Conic_section).
- [x] Query and process high accuracy ephemeris from NASA JPL's [Horizon](http://ssd.jpl.nasa.gov/?horizons) interface and automatically cache results using [Realm](https://realm.io) and SQLite.
- [x] Excellent offline mode. Stock ephemeris from 1500 AD to 3000 AD of major celestial bodies.
- [x] Support querying rise, transit and set timestamps for major celestial bodies.

> Conics model predicts the orbits of the major planets in our solar system pretty accurately. To account for [apsidal precession](https://en.wikipedia.org/wiki/Apsidal_precession) and other orbital perturbations of celestial bodies like Mercury and Earth's moon, Orbits fetches many data points from JPL and cherry-pick the orbital configuration closest to the reference time.

### ![Header image](https://github.com/DJBen/StarryNight/raw/master/External%20Assets/S-Green.png)

## StarryNight
[![Language](https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat)](https://swift.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

### Overview
_StarryNight is all you need for curiosity towards stars and constellations._

- Database of 15000+ stars within 7th magnitude.
  - [Star Catalogs](https://en.wikipedia.org/wiki/Star_catalogue) including HR, HD, HIP, [Gould](https://en.wikipedia.org/wiki/Gould_designation) and [Bayer](https://en.wikipedia.org/wiki/Bayer_designation)-[Flamsteed](https://en.wikipedia.org/wiki/Flamsteed_designation) designations.
  - Celestial coordinate and proper motion.
  - Visual and absolute magnitude, luminance, spectral type, binary star info, and other physical properties.
- Extended Constellation support.
  - Position query and inverse position query.
  - Constellation line and constellation border.
  - Abbreviation, genitive and etymology.


### Usage

#### Stars

1. All stars brighter than...

```swift
Star.magitudeLessThan(7)
```
2. Star with specific designation.

```swift
Star.hr(9077)
Star.hd(224750)
Star.hip(25)
```
3. Star closest to specific celestial coordinate.

This is very useful to locate the closest star to user input.

```swift
let coord = Vector3.init(equatorialCoordinate: EquatorialCoordinate.init(rightAscension: radians(hours: 5, minutes: 20), declination: radians(degrees: 10), distance: 1)).normalized()
Star.closest(to: coord, maximumMagnitude: 2.5)
// Bellatrix
```

#### Constellations

1. Constellation with name or [IAU symbol](https://www.iau.org/public/themes/constellations/).
```swift
Constellation.iau("Tau")
Constellation.named("Orion")
```
2. Constellation that contains specific celestial coordinate.

This is very useful to locate the constellation that contains the region of user input.

  It is implemented as a category on `EquatorialCoordinate`. See [SpaceTime](https://github.com/DJBen/SpaceTime) repo for implementation and usage of coordinate classes.

```swift
let coord = EquatorialCoordinate.init(rightAscension: 1.547, declination: 0.129, distance: 1)
coord.constellation
// Orion
```

3. Neighboring constellations and centers.

```swift
// Get a set of neighboring constellations
Constellation.iau("Ori").neighbors
// Get the coordinate of center(s) of current constellation
Constellation.iau("Ori").displayCenters
```

  *Note*: `displayCenters` returns an array of one element for all constellations except Serpens, which will include two elements - one center for Serpens Caput and the other for Serpens Cauda.

### Remarks
Data extracted from [HYG database](https://github.com/astronexus/HYG-Database) and processed into SQLite. The star catalog has been trimmed to 7th magnitude to reduce file size. Feel free to download the full catalog and import into SQLite whenever you see fit.

![Header](https://github.com/DJBen/SpaceTime/raw/master/External%20Assets/T-Blue.png)

# SpaceTime

[![Language](https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat)](https://swift.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Overview

- Conversion among [equatorial coordinate](https://en.wikipedia.org/wiki/Equatorial_coordinate_system) (right ascension and declination), [horizontal coordinate](https://en.wikipedia.org/wiki/Horizontal_coordinate_system) (azimuth and altitude),
[ecliptic coordinate](https://en.wikipedia.org/wiki/Ecliptic_coordinate_system) (longitude and latitude) and their corresponding Cartesian equivalents.
- Calculate [Julian Day](https://en.wikipedia.org/wiki/Julian_day) and [Local sidereal time](https://en.wikipedia.org/wiki/Sidereal_time).
- High precision calculation of the [obliquity of ecliptic](https://en.wikipedia.org/wiki/Ecliptic) good to 0″.04 / 1000 years over 10000 years.
- Matrix / Quaternion transformation from celestial coordinate system to local tangent plane. Supports [North-East-Down](https://en.wikipedia.org/wiki/North_east_down) coordinate from [earth-centered, earth-fixed](https://en.wikipedia.org/wiki/ECEF) coordinate system for any given longitude, latitude and timestamp.

## Demo
![Screenshot](https://github.com/DJBen/SpaceTime/raw/master/External%20Assets/Screenshot.png)

## Usage
Equatorial to horizontal coordinate:
```swift
// Supply observer location and timestamp
let locTime = ObserverLocationTime(location: location, timestamp: JulianDay.now)
let vegaCoord = EquatorialCoordinate(rightAscension: radians(hours: 18, minutes: 36, seconds: 56.33635), declination: radians(degrees: 38, minutes: 47, seconds: 1.2802), distance: 1)
// Azimuth and altitude of Vega
let vegaAziAlt = HorizontalCoordinate.init(equatorialCoordinate: vegaCoord, observerInfo: locTime)
```
Ecliptic coordinate of Pollux at standard equinox of J2000.0.
```swift
let ra = DegreeAngle(116.328942)
let dec = DegreeAngle(28.026183)
let eclipticCoord = EclipticCoordinate(longitude: ra, latitude: dec, distance: 1, julianDay: .J2000)
eclipticCoord.longitude.wrappedValue // 113.21563
eclipticCoord.latitude.wrappedValue // 6.68417
```
Greenwich Mean Sidereal Time:
```swift
SiderealTime.init(julianDay: JulianDay.now)
```
Local Apparent Sidereal Time:
```swift
// Get location from GPS or hard code
let locTime = ObserverLocationTime(location: location, timestamp: JulianDay.now)
let localSidTime = SiderealTime.init(observerLocationTime: locTime)
```
More use cases can be found in the source and test cases.

# Startracker
A startracker is included to obtain precise alignment to the stars when viewing at night.
To run tests on the startracker, you will first need to download the test image files from:
https://drive.google.com/drive/folders/1aB7_yC7U4iHJOtRk4fT2sOnFLDsacUH5?usp=sharing

Place all the image files into `StarryNight/Tests/Resources/`.

To further develop/test the startracker, there are two methods:
1. Simulation code from Python (see `py/README.md`)
2. Real images where stars have been externally identified. These images should ideally come
from the long-exposure photo capture functionality in Graviton's startracker, as those images
would represent what the app could realistically capture. The app saves all photos to the photo
library to facilitate this type of debugging.

Both types of images can be converted into unit tests on the Swift side.
