# Graviton :milky_way:

[![Language](https://img.shields.io/badge/Swift-3.1-orange.svg?style=flat)](https://swift.org)
[![Build Status](https://travis-ci.com/DJBen/Graviton.svg?token=1KVrf6xTWoPqLKJBPuJ1&branch=master)](https://travis-ci.com/DJBen/Graviton)
[![codebeat badge](https://codebeat.co/badges/de61d36c-440a-4cc7-85cf-97379e08ef15)](https://codebeat.co/a/sihao-lu/projects/github-com-djben-graviton-master?maxAge=3600)
[![AUR](https://img.shields.io/aur/license/yaourt.svg)]()

- _Real-time night sky and solar system rendering._
- _Astronomy and celestial mechanics toolkit._
- _Native Apple technologies with Swift 3 and SceneKit._
----
## App
- [x] Real-time night sky rendering. Fully customizable. Totally hackable.
- [x] Real-time high accuracy solar system illustration. In scale.
- [ ] Detailed celestial body information. Rise, transit and set information panel for :sunny:, :first_quarter_moon_with_face: and naked-eye planets.

## Frameworks
__Unless marked internal, all frameworks are available for standalone use.__
### Orbits
_High accuracy ephemeris query and orbital mechanics calculation framework._
- [x] Calculate [Keplarian](https://en.wikipedia.org/wiki/Kepler_orbit) orbital mechanics with support of all [conics](https://en.wikipedia.org/wiki/Conic_section).
- [x] Query and process high accuracy ephemeris from NASA JPL's [Horizon](http://ssd.jpl.nasa.gov/?horizons) interface and automatically cache results using [Realm](https://realm.io) and SQLite.
- [x] Excellent offline mode. Stock ephemeris from 1500 AD to 3000 AD of major celestial bodies.
- [x] Support querying rise, transit and set timestamps for major celestial bodies.

> Conics model predicts the orbits of the major planets in our solar system pretty accurately. To account for [apsidal precession](https://en.wikipedia.org/wiki/Apsidal_precession) and other orbital perturbations of celestial bodies like Mercury and Earth's moon, Orbits fetches many data points from JPL and cherry-pick the orbital configuration closest to the reference time.

### StarryNight
_A framework make convenient for reference to stars and constellations._
- Database of 15000+ stars within 7th magnitude.
  - HR, HD, HIP and Bayer-Flamsteed designations.
  - Celestial coordinate and proper motion.
  - Visual and absolute magnitude, luminance, spectral type binary star info, and other physical properties
- Position query, connection line and border support for constellations.

### SpaceTime
- [x] Astronomy coordinate conversion. Conversion among spherical coordinate `(RA, DEC)`, cylindrical coordinate `(Azi, Alt)` and Euclidean coordinate `(x, y, z)`.
- [x] [Local sidereal time](https://en.wikipedia.org/wiki/Sidereal_time) and local horizontal NED coordinate from ECEF transformation support.
- [x] Conversion between `Date` and [Julian Date](https://en.wikipedia.org/wiki/Julian_day).

### MathUtil (Internal)
- Double precision Matrix4, Quaternion and coordinate related transformation support.

## Goals
This is an amateurish project by an amateur astronomer. As a lover of science and space exploration, there are a few long-term goals:

- A full-fledged open source stellarium software
- An educational astronomy app with science in mind
- (?) A space flight simulator that utilizes [patched conics approximation](https://en.wikipedia.org/wiki/Patched_conic_approximation).

## Copyright
This project is licensed under GPLv3.
If you have issues with any assets or resources in Graviton, please don't hesitate to reach out [DJBen](mailto:lsh32768@gmail.com). No copyright issue is too small.
