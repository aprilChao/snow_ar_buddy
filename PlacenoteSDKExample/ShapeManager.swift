//
//  ShapeManager.swift
//  Shape Dropper (Placenote SDK iOS Sample)
//
//  Created by Prasenjit Mukherjee on 2017-10-20.
//  Copyright © 2017 Vertical AI. All rights reserved.
//

import Foundation
import SceneKit

extension String {
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }
    
    func appendToURL(fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(fileURL: fileURL)
    }
}


extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}

func generateRandomColor() -> UIColor {
    let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
    let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.3 // from 0.3 to 1.0 to stay away from white
    let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.3 // from 0.3 to 1.0 to stay away from black
    
    return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
}


//Class to manage a list of shapes to be view in Augmented Reality including spawning, managing a list and saving/retrieving from persistent memory using JSON
class ShapeManager {
    private var nodeName: Int = 0 
    private var scnScene: SCNScene!
    private var scnView: SCNView!
    
    private var shapeNodes: [ShapeNode] = []
    
    public var shapesDrawn: Bool! = false
    private var selectedSegment: Int = 0
    
    init(scene: SCNScene, view: SCNView) {
        scnScene = scene
        scnView = view
    }
    
    func getShapeArray() -> [[String: String]] {
        var shapeArray: [[String: String]] = []
        if (shapeNodes.count > 0) {
            for i in 0...(shapeNodes.count-1) {
                shapeArray.append(shapeNodes[i].toString())
            }
        }
        return shapeArray
    }
    
    // Load shape array
    func loadShapeArray(shapeArray: [[String: String]]?) -> Bool {
        clearShapes() //clear currently viewing shapes and delete any record of them.
        
        if (shapeArray == nil) {
            print ("Shape Manager: No shapes for this map")
            return false
        }
        
        for item in shapeArray! {
            shapeNodes.append(ShapeNode.toNode(item))
            
            print ("Shape Manager: Retrieved ")
        }
        
        print ("Shape Manager: retrieved " + String(shapeNodes.count) + " shapes")
        return true
    }
    
    func clearView() { //clear shapes from view
        for shapeNode in shapeNodes {
            let shape = shapeNode.getNode()
            shape.removeFromParentNode()
        }
        shapesDrawn = false
    }
    
    func drawView(parent: SCNNode) {
        print("run drawView")
        if(shapeNodes.count <= 0){
            print("no shapepositions")
            return
        }
        for shape in shapeNodes {
            parent.addChildNode(shape.getNode())
        }
        shapesDrawn = true
    }
    
    func clearShapes() { //delete all nodes and record of all shapes
        clearView()
        for shapeNode in shapeNodes {
            let node = shapeNode.getNode()
            node.geometry!.firstMaterial!.normal.contents = nil
            node.geometry!.firstMaterial!.diffuse.contents = nil
        }
        shapeNodes.removeAll()
    }
    
    func getShapeNodes() -> [SCNNode]{
        var nodeArray: [SCNNode] = []
        for shapeNode in shapeNodes {
            nodeArray.append(shapeNode.getNode())
        }
        return nodeArray
    }
    
    func spawnShape(position: SCNVector3, nodeType: Int, path: Int) {
        //let shapeType: ShapeType = ShapeType.random()
        selectedSegment = nodeType
        let shapeType: ShapeType
        let color: String
        if(nodeType == 1){
            shapeType = ShapeType.genArrow()
            color = "blue"
        }else if(nodeType == 0){
            shapeType = ShapeType.genSphere()
            color = "purple"
        }else{
            shapeType = ShapeType.genPyramid()
            color = "green"
        }
        placeShape(position: position, type: shapeType, color: color, path: path)
    }
    
    func placeShape (position: SCNVector3, type: ShapeType, color: String, path: Int) {
        let shapeNode = ShapeNode(name: nodeName, type: type, path: path, color: color, position: position, orientation: [0,0,0], scale: [1,1,1])
        nodeName += 1
        let node = shapeNode.getNode()
        if(selectedSegment == 0){
            node.name = "Start"
        }else if(selectedSegment == 1){
            node.name = "Arrow"
            shapeNode.rotateNode(x: 90, y: 180, z: 0)
        }else{
            node.name = "Destination"
        }
        scnScene.rootNode.addChildNode(node)
        shapesDrawn = true
    }
    
    func loadPath(path: Int, parent: SCNNode){
        clearView()
        print("run loadpath")
        var pathNodes: [SCNNode] = []
        if(shapeNodes.count <= 0){
            print("no shapepositions")
            return
        }
        for i in 0...(shapeNodes.count-1) {
            if(path == shapeNodes[i].getPath()){
                pathNodes.append(shapeNodes[i].getNode())
            }
        }
        for shape in pathNodes {
            parent.addChildNode(shape)
        }
        shapesDrawn = true
    }
    
}
