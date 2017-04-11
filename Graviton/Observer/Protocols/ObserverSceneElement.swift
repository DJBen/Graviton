//
//  ObserverSceneElement.swift
//  Graviton
//
//  Created by Sihao Lu on 4/9/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

/// Protocol node or a group of similarly behaved node in the observer scene
/// with settings support
@objc protocol ObserverSceneElement {
    /// Whether the element is set up
    var isSetUp: Bool { get }
    
    /// Set up the element; this is a potentially expensive operation.
    func setUpElement()
    
    /// Show the element; this operation should be very cheap if the element is already set up. Will invoke setupElement if it's not set up
    @objc optional func showElement()
    
    /// Hide the element; this operation should be very cheap.
    @objc optional func hideElement()
    
    /// Remove the element; this operation should erase the object from data model and deallocate any resources.
    func removeElement()
}
