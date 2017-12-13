//
//  RealmManager.swift
//  Graviton
//
//  Created by Sihao Lu on 12/13/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import RealmSwift
import Orbits

class RealmManager {
    static let `default` = RealmManager()

    func migrateRealmIfNeeded() {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 1,

            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { _, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if oldSchemaVersion < 1 {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })

        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config

        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        _ = try! Realm()
    }

    func clearRedundantRealm(daysAgo: Double = 3) {
        // Remove all cached realm objects more than a few days ago
        CelestialBodyObserverInfo.clearOutdatedInfo(daysAgo: daysAgo)
        RiseTransitSetElevation.clearOutdatedInfo(daysAgo: daysAgo)
    }
}
