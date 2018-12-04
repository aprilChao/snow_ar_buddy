//
//  Wall.swift
//  PlacenoteSDKExample
//
//  Created by April Chao on 12/4/18.
//  Copyright © 2018 Vertical. All rights reserved.
//

import Foundation
import SceneKit

class Wall{
    private var start: SCNNode
    private var end: SCNNode
    
    init(start s: SCNNode, end e: SCNNode){
        start = s
        end = e
    }
}
