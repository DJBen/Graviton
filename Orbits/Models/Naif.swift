//
//  Naif.swift
//  Orbits
//
//  Created by Ben Lu on 1/29/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation

// https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/FORTRAN/req/naif_ids.html#NAIF%20Object%20ID%20numbers

public enum Naif: Comparable, Hashable, ExpressibleByIntegerLiteral, CustomStringConvertible {
    public enum MajorBody: Int {
        case mercury = 199
        case venus = 299
        case earth = 399
        case mars = 499
        case jupiter = 599
        case saturn = 699
        case uranus = 799
        case neptune = 899
        case pluto = 999

        public var moons: [Moon] {
            return (1...98).compactMap { Moon(rawValue: $0) }
        }
    }

    public enum Moon: Int {
        case luna = 301
        case phobos = 401
        case deimos = 402
        case io = 501
        case europa = 502
        case ganymede = 503
        case callisto = 504
        case amalthea = 505
        case himalia = 506
        case elara = 507
        case pasiphae = 508
        case sinope = 509
        case lysithea = 510
        case carme = 511
        case ananke = 512
        case leda = 513
        case thebe = 514
        case adrastea = 515
        case metis = 516
        case callirrhoe = 517
        case themisto = 518
        case magaclite = 519
        case taygete = 520
        case chaldene = 521
        case harpalyke = 522
        case kalyke = 523
        case iocaste = 524
        case erinome = 525
        case isonoe = 526
        case praxidike = 527
        case autonoe = 528
        case thyone = 529
        case hermippe = 530
        case aitne = 531
        case eurydome = 532
        case euanthe = 533
        case euporie = 534
        case orthosie = 535
        case sponde = 536
        case kale = 537
        case pasithee = 538
        case hegemone = 539
        case mneme = 540
        case aoede = 541
        case thelxinoe = 542
        case arche = 543
        case kallichore = 544
        case helike = 545
        case carpo = 546
        case eukelade = 547
        case cyllene = 548
        case kore = 549
        case herse = 550
        case mimas = 601
        case enceladus = 602
        case tethys = 603
        case dione = 604
        case rhea = 605
        case titan = 606
        case hyperion = 607
        case iapetus = 608
        case phoebe = 609
        case janus = 610
        case epimetheus = 611
        case helene = 612
        case telesto = 613
        case calypso = 614
        case atlas = 615
        case prometheus = 616
        case pandora = 617
        case pan = 618
        case ymir = 619
        case paaliaq = 620
        case tarvos = 621
        case ijiraq = 622
        case suttungr = 623
        case kiviuq = 624
        case mundilfari = 625
        case albiorix = 626
        case skathi = 627
        case erriapus = 628
        case siarnaq = 629
        case thrymr = 630
        case narvi = 631
        case methone = 632
        case pallene = 633
        case polydeuces = 634
        case daphnis = 635
        case aegir = 636
        case bebhionn = 637
        case bergelmir = 638
        case bestla = 639
        case farbauti = 640
        case fenrir = 641
        case fornjot = 642
        case hati = 643
        case hyrrokkin = 644
        case kari = 645
        case loge = 646
        case skoll = 647
        case surtur = 648
        case anthe = 649
        case jarnsaxa = 650
        case greip = 651
        case tarqeq = 652
        case aegaeon = 653
        case ariel = 701
        case umbriel = 702
        case titania = 703
        case oberon = 704
        case miranda = 705
        case cordelia = 706
        case ophelia = 707
        case bianca = 708
        case cressida = 709
        case desdemona = 710
        case juliet = 711
        case portia = 712
        case rosalind = 713
        case belinda = 714
        case puck = 715
        case caliban = 716
        case sycorax = 717
        case prospero = 718
        case setebos = 719
        case stephano = 720
        case trinculo = 721
        case francisco = 722
        case margaret = 723
        case ferdinand = 724
        case perdita = 725
        case mab = 726
        case cupid = 727
        case triton = 801
        case nereid = 802
        case naiad = 803
        case thalassa = 804
        case despina = 805
        case galatea = 806
        case larissa = 807
        case proteus = 808
        case halimede = 809
        case psamathe = 810
        case sao = 811
        case laomedeia = 812
        case neso = 813
        case charon = 901
        case nix = 902
        case hydra = 903
        case kerberos = 904
        case styx = 905

        public var primary: MajorBody {
            return MajorBody(rawValue: self.rawValue / 100 * 100 + 99)!
        }
    }

    case majorBody(MajorBody)
    case moon(Moon)
    case sun
    case custom(Int)

    static let planets: [Naif] = {
        let planets: [MajorBody] = [.mercury, .venus, .earth, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]
        return planets.map { .majorBody($0) }
    }()

    public var description: String {
        switch self {
        case let .majorBody(mb):
            return String(describing: mb).capitalized
        case .sun:
            return "Sun"
        case let .moon(m):
            if m == .luna {
                return "Moon"
            }
            return String(describing: m).capitalized
        default:
            fatalError()
        }
    }

    public var rawValue: Int {
        switch self {
        case let .majorBody(mb):
            return mb.rawValue
        case .sun:
            return 10
        case let .moon(m):
            return m.rawValue
        case let .custom(customId):
            return customId
        }
    }

    public var hashValue: Int {
        return rawValue
    }

    public var primary: Naif? {
        switch self {
        case .sun:
            return nil
        case .majorBody:
            return .sun
        case .moon(let m):
            return .majorBody(m.primary)
        case .custom:
            return nil
        }
    }

    public var moons: [Naif] {
        switch self {
        case .sun:
            return Naif.planets
        case .majorBody(let mb):
            return mb.moons.map { .moon($0) }
        default:
            return []
        }
    }

    public init(integerLiteral value: Int) {
        self.init(naifId: value)
    }

    public init(naifId: Int) {
        if naifId == 10 {
            self = .sun
        } else if naifId % 100 == 99 {
            if let mb = Naif.MajorBody(rawValue: naifId) {
                self = .majorBody(mb)
            } else {
                fatalError("major planet naif id not found")
            }
        } else if naifId / 100 < 10 {
            if let m = Naif.Moon(rawValue: naifId) {
                self = .moon(m)
            } else {
                fatalError("moon naif id not found")
            }
        } else {
            self = .custom(naifId)
        }
    }

    /// Returns whether the current celestial body is the primary of the other
    ///
    /// - Parameter otherNaif: Naif code of other celestial body
    /// - Returns: Whether the current celestial body is the primary of the other
    public func isPrimary(of otherNaif: Naif) -> Bool {
        switch self {
        case .moon:
            return false
        case .sun:
            if case .majorBody = otherNaif {
                return true
            } else {
                return false
            }
        case .majorBody(let mb):
            if case let .moon(m) = otherNaif {
                return mb.rawValue / 100 == m.rawValue / 100
            } else {
                return false
            }
        case .custom:
            return false
        }
    }

    public func isSatellite(of otherNaif: Naif) -> Bool {
        switch self {
        case .moon(let m):
            if case let .majorBody(mb) = otherNaif {
                return mb.rawValue / 100 == m.rawValue / 100
            }
            return false
        case .majorBody:
            if case .sun = otherNaif {
                return true
            } else {
                return false
            }
        case .sun:
            return false
        case .custom:
            return false
        }
    }

    public static func <(lhs: Naif, rhs: Naif) -> Bool {
        if lhs.rawValue == rhs.rawValue {
            return false
        }
        // 10 < x99 < x01-x89
        if lhs.rawValue == 10 {
            return true
        } else if rhs.rawValue == 10 {
            return false
        }
        if lhs.rawValue / 100 == rhs.rawValue / 100 {
            if lhs.rawValue % 100 == 99 {
                return true
            } else if rhs.rawValue % 100 == 99 {
                return false
            }
            return lhs.rawValue < rhs.rawValue
        } else {
            // 1xx < 2xx < 3xx
            return lhs.rawValue < rhs.rawValue
        }
    }

    public static func ==(lhs: Naif, rhs: Naif) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension Naif {
    var parents: Set<Naif> {
        var results = Set<Naif>()
        results.insert(self)
        var current: Naif? = self
        while let p = current?.primary {
            results.insert(p)
            current = current?.primary
        }
        return results
    }
}
