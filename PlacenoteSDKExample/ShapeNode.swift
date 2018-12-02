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
    private var nodePath: Int
    private var nodeType: ShapeType
    private var nodeColor: String
    private var nodePosition: SCNVector3
    private var node: SCNNode = SCNNode()
    private var nodeOrientation: [CGFloat]
    //SCNAction.rotateBy(x: toRadian(10), y: toRadian(20), z: toRadian(30), duration: 0)
    //orientation: [x,y,z]
    
    init(type: ShapeType, path: Int, color: String, position: SCNVector3, orientation: [CGFloat]){
        nodePath = path
        nodeType = type
        nodeColor = color
        nodePosition = position
        nodeOrientation = orientation
        node = createNode()
    }
    
    func toRadian(_ degrees: CGFloat)-> CGFloat{
        return CGFloat(degrees) * CGFloat.pi / 180
    }
    
    func rotateNode(x: CGFloat, y: CGFloat, z: CGFloat){
        nodeOrientation[0] += x
        nodeOrientation[1] += y
        nodeOrientation[2] += z
        print(nodeOrientation)
        node.runAction(SCNAction.rotateBy(x: toRadian(x), y: toRadian(y), z: toRadian(z), duration: 0))
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
            geometry.materials.first?.diffuse.contents = getColor()
            
            let geometryNode = SCNNode(geometry: geometry)
            geometryNode.position = nodePosition
            geometryNode.physicsBody = SCNPhysicsBody.static()
            if nodeType.rawValue == 1{
                geometryNode.scale = SCNVector3(x:0.22, y:0.22, z:0.22)
            }else if nodeType.rawValue == 2{
                geometryNode.scale = SCNVector3(x:0.18, y:0.2, z:0.18)
            }else{
                geometryNode.scale = SCNVector3(x:0.4, y:0.4, z:0.3)
        }
            
            return geometryNode
    }
    
    func toString() -> [String: String]{
        let temp = ["path": "\(nodePath)", "type": "\(nodeType.rawValue)", "color": "\(nodeColor)", "pos-x": "\(nodePosition.x)",  "pos-y": "\(nodePosition.y)",  "pos-z": "\(nodePosition.z)", "orient-x": "\(nodeOrientation[0])", "orient-y": "\(nodeOrientation[1])", "orient-z": "\(nodeOrientation[2])"]
        print(temp)
        return temp
    }
    
    static func toNode(_ strArr: [String: String]) -> ShapeNode{
        print(strArr)
        let path = Int(strArr["path"]!)
        let type = ShapeType(rawValue: Int(strArr["type"]!)!)!
        let color = strArr["color"]
        let position = SCNVector3(x: Float(strArr["pos-x"]!)!, y: Float(strArr["pos-y"]!)!, z: Float(strArr["pos-z"]!)!)
        //let orientation = [CGFloat(strArr["orient-x"]!), CGFloat(strArr["orient-y"]!), CGFloat(strArr["orient-z"]!)]
        let ox: String = strArr["orient-x"]!
        let oy: String = strArr["orient-y"]!
        let oz: String = strArr["orient-z"]!
        let orientation = [CGFloat(NumberFormatter().number(from: ox)!), CGFloat(NumberFormatter().number(from: oy)!), CGFloat(NumberFormatter().number(from: oz)!)]
        return ShapeNode(type: type, path: path!, color: color!, position: position, orientation: orientation)
    }
}
