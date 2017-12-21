//
//  OccationalPrompt.swift
//  Graviton
//
//  Created by Sihao Lu on 12/20/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

struct OccationalPrompt {
    private static let occationalPromptPrefix = "occationalPrompt"

    static func recordPrompt(forKey key: String) {
        UserDefaults.standard.set(Date(), forKey: "\(occationalPromptPrefix).\(key)")
    }

    static func shouldShowPrompt(forKey key: String, timeInterval: TimeInterval) -> Bool {
        guard let lastPromptDate = UserDefaults.standard.object(forKey: "\(occationalPromptPrefix).\(key)") as? Date else {
            return true
        }
        return Date().timeIntervalSince(lastPromptDate) > timeInterval
    }
}
