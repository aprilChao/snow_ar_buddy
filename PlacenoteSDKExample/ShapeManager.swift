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
    
    private var scnScene: SCNScene!
    private var scnView: SCNView!
    
    private var shapePositions: [SCNVector3] = []
    private var shapeTypes: [ShapeType] = []
    private var shapeNodes: [SCNNode] = []
    private var shapePaths: [Int] = []
    
    public var shapesDrawn: Bool! = false
    private var selectedSegment: Int = 0
    
    init(scene: SCNScene, view: SCNView) {
        scnScene = scene
        scnView = view
    }
    
    func getShapeArray() -> [[String: [String: String]]] {
        var shapeArray: [[String: [String: String]]] = []
        if (shapePositions.count > 0) {
            for i in 0...(shapePositions.count-1) {
                shapeArray.append(["shape": ["style": "\(shapeTypes[i].rawValue)", "x": "\(shapePositions[i].x)",  "y": "\(shapePositions[i].y)",  "z": "\(shapePositions[i].z)", "path": "\(shapePaths[i])" ]])
            }
        }
        return shapeArray
    }
    
    // Load shape array
    func loadShapeArray(shapeArray: [[String: [String: String]]]?) -> Bool {
        clearShapes() //clear currently viewing shapes and delete any record of them.
        
        if (shapeArray == nil) {
            print ("Shape Manager: No shapes for this map")
            return false
        }
        
        for item in shapeArray! {
            let x_string: String = item["shape"]!["x"]!
            let y_string: String = item["shape"]!["y"]!
            let z_string: String = item["shape"]!["z"]!
            let position: SCNVector3 = SCNVector3(x: Float(x_string)!, y: Float(y_string)!, z: Float(z_string)!)
            let path: Int = Int(item["shape"]!["path"]!)!
            let type: ShapeType = ShapeType(rawValue: Int(item["shape"]!["style"]!)!)!
            shapePositions.append(position)
            shapeTypes.append(type)
            shapeNodes.append(createShape(position: position, type: type, color: getColor()))
            shapePaths.append(path)
            
            print ("Shape Manager: Retrieved " + String(describing: type) + " type at position" + String (describing: position))
        }
        
        print ("Shape Manager: retrieved " + String(shapePositions.count) + " shapes")
        return true
    }
    
    func clearView() { //clear shapes from view
        for shape in shapeNodes {
            shape.removeFromParentNode()
        }
        shapesDrawn = false
    }
    
    func drawView(parent: SCNNode) {
        print("run drawView")
        if(shapePositions.count <= 0){
            print("no shapepositions")
            return
        }
        for shape in shapeNodes {
            parent.addChildNode(shape)
        }
        shapesDrawn = true
    }
    
    func clearShapes() { //delete all nodes and record of all shapes
        clearView()
        for node in shapeNodes {
            node.geometry!.firstMaterial!.normal.contents = nil
            node.geometry!.firstMaterial!.diffuse.contents = nil
        }
        shapeNodes.removeAll()
        shapePositions.removeAll()
        shapeTypes.removeAll()
    }
    
    func getShapeNodes() -> [SCNNode]{
        return shapeNodes
    }
    
    func spawnShape(position: SCNVector3, nodeType: Int, path: Int) {
        //let shapeType: ShapeType = ShapeType.random()
        selectedSegment = nodeType
        let shapeType: ShapeType
        let color: UIColor
        if(nodeType == 1){
            shapeType = ShapeType.genArrow()
            color = UIColor(red: 0.344, green: 0.972, blue: 1.000, alpha: 1.000)
        }else if(nodeType == 0){
            shapeType = ShapeType.genSphere()
            color = UIColor.purple
        }else{
            shapeType = ShapeType.genPyramid()
            color = UIColor.green
        }
        placeShape(position: position, type: shapeType, color: color, path: path)
    }
    
    func getColor() -> UIColor{
        let color: UIColor
        if(selectedSegment == 1){
            color = UIColor(red: 0.344, green: 0.972, blue: 1.000, alpha: 1.000)
        }else if(selectedSegment == 0){
            color = UIColor.purple
        }else{
            color = UIColor.green
        }
        return color
    }
    
    func placeShape (position: SCNVector3, type: ShapeType, color: UIColor, path: Int) {
        
        let geometryNode: SCNNode = createShape(position: position, type: type, color: color)
        if(selectedSegment == 0){
            geometryNode.name = "Start"
        }else if(selectedSegment == 1){
            geometryNode.name = "Arrow"
            geometryNode.runAction(SCNAction.rotateBy(x: 0, y: (180 * .pi / 180), z: 0, duration: 0))
            geometryNode.runAction(SCNAction.rotateBy(x: (90 * .pi / 180), y: 0, z: 0, duration: 0)) 
        }else{
            geometryNode.name = "Destination"
        }
        shapePositions.append(position)
        shapeTypes.append(type)
        shapeNodes.append(geometryNode)
        shapePaths.append(path)
        
        scnScene.rootNode.addChildNode(geometryNode)
        shapesDrawn = true
    }
    
    func createShape (position: SCNVector3, type: ShapeType, color: UIColor) -> SCNNode {
        
        let geometry:SCNGeometry = ShapeType.generateGeometry(s_type: type)
        //let color = generateRandomColor()
        geometry.materials.first?.diffuse.contents = color
        
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.position = position
        geometryNode.physicsBody = SCNPhysicsBody.static()
        if selectedSegment == 1{
            geometryNode.scale = SCNVector3(x:0.5, y:0.5, z:0.4)
        }else{
            geometryNode.scale = SCNVector3(x:0.2, y:0.2, z:0.2)
        }
        
        return geometryNode
    }
    
    func loadPath(path: Int, parent: SCNNode){
        clearView()
        print("run loadpath")
        var pathNodes: [SCNNode] = []
        if(shapePositions.count <= 0){
            print("no shapepositions")
            return
        }
        for i in 0...(shapePositions.count-1) {
            if(path == shapePaths[i]){
                pathNodes.append(shapeNodes[i])
            }
        }
        for shape in pathNodes {
            parent.addChildNode(shape)
        }
        shapesDrawn = true
    }
    
}
