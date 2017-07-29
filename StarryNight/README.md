# StarryNight
[![Language](https://img.shields.io/badge/Swift-3.1-orange.svg?style=flat)](https://swift.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Overview
_StarryNight is all you need for curiosity towards stars and constellations._

- Database of 15000+ stars within 7th magnitude.
  - [Star Catalogs](https://en.wikipedia.org/wiki/Star_catalogue) including HR, HD, HIP, [Gould](https://en.wikipedia.org/wiki/Gould_designation) and [Bayer](https://en.wikipedia.org/wiki/Bayer_designation)-[Flamsteed](https://en.wikipedia.org/wiki/Flamsteed_designation) designations.
  - Celestial coordinate and proper motion.
  - Visual and absolute magnitude, luminance, spectral type, binary star info, and other physical properties.
- Extended Constellation support.
  - Position query and inverse position query.
  - Constellation line and constellation border.
  - Abbreviation, genitive and etymology.

## Installation

### Carthage

    github "DJBen/StarryNight" ~> 0.1.0

## Usage

### TODO

## Remarks
Data extracted from [HYG database](https://github.com/astronexus/HYG-Database) and processed into SQLite. The star catalog has been trimmed to 7th magnitude to reduce file size. Feel free to download the full catalog and import into SQLite whenever you see fit.
