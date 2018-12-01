//
//  ShapeNode.swift
//  PlacenoteSDKExample
//
//  Created by April Chao on 12/1/18.
//  Copyright © 2018 Vertical. All rights reserved.
//

import Foundation
import SceneKit

class ShapeNode{
    private var nodeName: Int
    private var nodePath: Int
    private var nodeType: ShapeType
    private var nodeColor: String
    private var nodePosition: SCNVector3
    private var node: SCNNode = SCNNode()
    private var nodeOrientation: [CGFloat]
    private var nodeScale: [Float]
    //SCNAction.rotateBy(x: toRadian(10), y: toRadian(20), z: toRadian(30), duration: 0)
    //orientation: [x,y,z]
    
    init(name: Int, type: ShapeType, path: Int, color: String, position: SCNVector3, orientation: [CGFloat], scale: [Float]){
        nodeName = name
        nodePath = path
        nodeType = type
        nodeColor = color
        nodePosition = position
        nodeOrientation = orientation
        nodeScale = scale
        node = createNode()
    }
    
    func toRadian(_ degrees: CGFloat)-> CGFloat{
        return CGFloat(degrees) * CGFloat.pi / 180
    }
    
    func rotateNode(x: CGFloat, y: CGFloat, z: CGFloat){
        nodeOrientation[0] += x
        nodeOrientation[1] += y
        nodeOrientation[2] += z
        node.runAction(SCNAction.rotateBy(x: toRadian(x), y: toRadian(y), z: toRadian(z), duration: 0))
    }
    
    func scaleNode(x: Float, y: Float, z: Float){
        nodeScale[0] = x
        nodeScale[1] = y
        nodeScale[2] = z
        node.scale = SCNVector3(x: x, y: y, z: z)
    }
    
    func getName() -> Int{
        return nodeName
    }
    
    func getPath() -> Int{
        return nodePath
    }
    
    func getNode() -> SCNNode{
        return node
    }
    
    func getColor() -> UIColor{
        if(nodeColor == "green"){
            return UIColor.green
        }else if(nodeColor == "blue"){
            return UIColor.blue
        }else{
            return UIColor.purple
        }
    }
    
    func createNode() -> SCNNode{
            let geometry: SCNGeometry = ShapeType.generateGeometry(s_type: nodeType)
            geometry.materials.first?.diffuse.contents = nodeColor
            
            let geometryNode = SCNNode(geometry: geometry)
            geometryNode.position = nodePosition
            geometryNode.physicsBody = SCNPhysicsBody.static()
            if nodePath == 1{
                scaleNode(x:0.5, y:0.5, z:0.4)
            }else{
                scaleNode(x:0.2, y:0.2, z:0.2)
            }
            
            return geometryNode
    }
    
    func toString() -> [String: String]{
        return ["name": "\(nodeName)", "path": "\(nodePath)", "type": "\(nodeType.rawValue)", "color": "\(nodeColor)", "pos-x": "\(nodePosition.x)",  "pos-y": "\(nodePosition.y)",  "pos-z": "\(nodePosition.z)", "orient-x": "\(nodeOrientation[0])", "orient-y": "\(nodeOrientation[1])", "orient-z": "\(nodeOrientation[2])", "scale-x": "\(nodeScale[0])", "scale-y": "\(nodeScale[1])", "scale-z": "\(nodeScale[2])"]
    }
    
    static func toNode(_ strArr: [String: String]) -> ShapeNode{
        let name = Int(strArr["name"]!)
        let path = Int(strArr["path"]!)
        let type = ShapeType(rawValue: Int(strArr["type"]!)!)!
        let color = strArr["color"]
        let position = SCNVector3(x: Float(strArr["pos-x"]!)!, y: Float(strArr["pos-y"]!)!, z: Float(strArr["pos-z"]!)!)
        //let orientation = [CGFloat(strArr["orient-x"]!), CGFloat(strArr["orient-y"]!), CGFloat(strArr["orient-z"]!)]
        let ox: String = strArr["orient-x"]!
        let oy: String = strArr["orient-y"]!
        let oz: String = strArr["orient-z"]!
        let orientation = [CGFloat(NumberFormatter().number(from: ox)!), CGFloat(NumberFormatter().number(from: oy)!), CGFloat(NumberFormatter().number(from: oz)!)]
        let sx: String = strArr["scale-x"]!
        let sy: String = strArr["scale-y"]!
        let sz: String = strArr["scale-z"]!
        let scale = [Float(NumberFormatter().number(from: sx)!), Float(NumberFormatter().number(from: sy)!), Float(NumberFormatter().number(from: sz)!)]
        return ShapeNode(name: name!, type: type, path: path!, color: color!, position: position, orientation: orientation, scale: scale)
    }
}
