# Graviton
[![codebeat badge](https://codebeat.co/badges/de61d36c-440a-4cc7-85cf-97379e08ef15)](https://codebeat.co/a/sihao-lu/projects/github-com-djben-graviton-master)

_Astronomy and orbital mechanics kit on iOS in modern Swift 3_

## Structure
### Graviton App
A showcase for constellations, planetary movement and orbital mechanics
### Orbits
A framework that does the heavylifting of accurate orbit calculations
- Calculate [Keplarian](https://en.wikipedia.org/wiki/Kepler_orbit) orbital mechanics for all [conics](https://en.wikipedia.org/wiki/Conic_section)
- Fetch and read ephemeris from JPL's [Horizon](http://ssd.jpl.nasa.gov/?horizons) batch interface
- Database support for caching fetched ephemeris
- Stock yearly ephemeris for major planets from 1500 AD to 3000 AD and monthly ephemeris for over 50 moons with a few exceptions

Conics model predicts the orbits of the major planets in our solar system pretty accurately. To account for [apsidal precession](https://en.wikipedia.org/wiki/Apsidal_precession) and other orbital perturbations of celestial bodies like Mercury and Earth's moon, Orbits fetches many data points from JPL and cherry-pick the orbital configuration closest to the reference time

### StarryNight
A framework make convenient for reference to stars and constellations
- Database of 15000+ stars within 7th magnitude
  - HR, HD, HIP and Bayer-Flamsteed designations
  - `RA, DEC`, or `x, y, z` and proper motion
  - Visual and absolute magnitude, luminance, spectral type binary star info, and other physical properties
- Query, connection line and border support for constellations

### SpaceTime
Ask yourself. What star is over my zenith? What time is it on Mars?
- Conversion among spherical coordinate `(RA, DEC)`, cylindrical coordinate `(Azi, Alt)` and Euclidean coordinate `(x, y, z)`
- [Local sidereal time](https://en.wikipedia.org/wiki/Sidereal_time) support
- [Julidan Date](https://en.wikipedia.org/wiki/Julian_day) support. This is so important that the two frameworks above rely on `SpaceTime`

## Goals
Although this is an hobby project, it introduces me to the realm of Astronomy with much deeper understanding than any of the amateurish courses offered by my college.

As a lover of science and space exploration, there are a few long-term goals:

- A full-fledged stellarium software
- A graphically pleasing illustration of our real time solar system
- A space flight simulator that utilizes [patched conics approximation](https://en.wikipedia.org/wiki/Patched_conic_approximation)
