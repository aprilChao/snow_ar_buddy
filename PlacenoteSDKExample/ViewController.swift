//
//  ViewController.swift
//  Shape Dropper (Placenote SDK iOS Sample)
//
//  Created by Prasenjit Mukherjee on 2017-09-01.
//  Copyright © 2017 Vertical AI. All rights reserved.
//

import UIKit
import CoreLocation
import SceneKit
import ARKit
import PlacenoteSDK

enum BodyType: Int {
  case start = 1
  case arrow = 2
  case destination = 4
  case camera = 8
}

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UITableViewDelegate, UITableViewDataSource, PNDelegate, CLLocationManagerDelegate, SCNPhysicsContactDelegate {
  
  
  //UI Elements
  @IBOutlet var scnView: ARSCNView!
  
  //UI Elements for the map table
  @IBOutlet var mapTable: UITableView!
  @IBOutlet var filterLabel2: UILabel!
  @IBOutlet var filterLabel1: UILabel!
  @IBOutlet var filterSlider: UISlider!
  
  
  @IBOutlet var newMapButton: UIButton!
  @IBOutlet var pickMapButton: UIButton!
  @IBOutlet var statusLabel: UILabel!
  @IBOutlet var showPNLabel: UILabel!
  @IBOutlet var showPNSelection: UISwitch!
  @IBOutlet var deleteNodeSelection: UISwitch!
  @IBOutlet var planeDetLabel: UILabel!
  @IBOutlet var deleteNodeLabel: UILabel!
  @IBOutlet var planeDetSelection: UISwitch!
  @IBOutlet var fileTransferLabel: UILabel!
  @IBOutlet var nodeTypeSelection: UISegmentedControl!
  @IBOutlet var nodeTypeLabel: UILabel!
  @IBOutlet var pathSelection: UISegmentedControl!
  @IBOutlet var pathLabel: UILabel!
  @IBOutlet var levelLabel: UILabel!
  @IBOutlet var levelUpButton: UIButton!
  @IBOutlet var levelDownButton: UIButton!
    @IBOutlet var creatorModeSelection: UISwitch!
    @IBOutlet var creatorModeLabel: UILabel!
    
  //AR Scene
  private var scnScene: SCNScene!
  private var cameraNode: SCNNode!
  
  //Status variables to track the state of the app with respect to libPlacenote
  private var trackingStarted: Bool = false;
  private var mappingStarted: Bool = false;
  private var localizationStarted: Bool = false;
  private var reportDebug: Bool = false
  private var maxRadiusSearch: Float = 500.0 //m
  private var currRadiusSearch: Float = 0.0 //m
  
  
  //Application related variables
  private var shapeManager: ShapeManager!
  private var tapRecognizer: UITapGestureRecognizer? = nil //initialized after view is loaded
  
  
  //Variables to manage PlacenoteSDK features and helpers
  private var maps: [(String, LibPlacenote.MapMetadata)] = [("Sample Map", LibPlacenote.MapMetadata())]
  private var camManager: CameraManager? = nil;
  private var ptViz: FeaturePointVisualizer? = nil;
  private var planesVizAnchors = [ARAnchor]();
  private var planesVizNodes = [UUID: SCNNode]();
  
  private var showFeatures: Bool = true
  private var creationMode: Bool = false
  private var planeDetection: Bool = false
  private var deleteNode: Bool = false
  private var collisionFeature: Bool = false
  private var selectedNodeType: Int = 0
  private var selectedPath: Int = 0
  
  private var locationManager: CLLocationManager!
  private var lastLocation: CLLocation? = nil
  
  //Setup view once loaded
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    setupScene()
    
    //App Related initializations
    shapeManager = ShapeManager(scene: scnScene, view: scnView)
    tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
    //tapRecognizer!.numberOfTapsRequired = 1
    tapRecognizer!.isEnabled = false
    scnView.addGestureRecognizer(tapRecognizer!)
    
    //IMPORTANT: need to run this line to subscribe to pose and status events
    //Declare yourself to be one of the delegates of PNDelegate to receive pose and status updates
    LibPlacenote.instance.multiDelegate += self;
    
    //Initialize tableview for the list of maps
    mapTable.delegate = self
    mapTable.dataSource = self
    mapTable.allowsSelection = true
    mapTable.isUserInteractionEnabled = true
    mapTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    
    //UI Updates
    newMapButton.isEnabled = false
    toggleMappingUI(true) //hide mapping UI options
    locationManager = CLLocationManager()
    locationManager.requestWhenInUseAuthorization()
    
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self;
      locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
      locationManager.startUpdatingLocation()
    }
  }
  
  //Initialize view and scene
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    configureSession();
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    scnView.session.pause()
  }
  
  func createCameraNode(){
    let ball = SCNCapsule(capRadius:0.05, height:2.0)
    ball.materials.first?.diffuse.contents = UIColor(hue: 0, saturation: 0, brightness: 0, alpha: 0)
    //ball.materials.first?.diffuse.contents = UIColor.red
    cameraNode = SCNNode(geometry: ball)
    cameraNode.position = SCNVector3Make(0, 0, 0.5)
    cameraNode.name = "Camera"
    
    let body = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: cameraNode))
    cameraNode.physicsBody = body
    cameraNode.physicsBody?.isAffectedByGravity = false
    cameraNode.physicsBody?.collisionBitMask = BodyType.start.rawValue | BodyType.arrow.rawValue | BodyType.destination.rawValue
    
    cameraNode.physicsBody?.categoryBitMask = BodyType.camera.rawValue
    cameraNode.physicsBody?.contactTestBitMask = BodyType.start.rawValue | BodyType.arrow.rawValue | BodyType.destination.rawValue
    
    scnView.pointOfView?.addChildNode(cameraNode)
  }
  
  func setupCollisions(){        
    /*self.scnView.scene.rootNode.enumerateChildNodes { (node, _) in
     let nodeName = node.name
     if(nodeName!.hasPrefix("Start")){
     print("In Start")
     let start = node
     
     let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: start))
     start.physicsBody = body
     start.physicsBody?.categoryBitMask = BodyType.start.rawValue
     }else if(nodeName!.hasPrefix("Arrow")){
     print("In Arrow")
     let arrow = node
     
     let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: arrow))
     arrow.physicsBody = body
     arrow.physicsBody?.categoryBitMask = BodyType.arrow.rawValue
     }else if(nodeName!.hasPrefix("Destination")){
     print("In Destination")
     let destination = node
     
     let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: destination))
     destination.physicsBody = body
     destination.physicsBody?.categoryBitMask = BodyType.destination.rawValue
     }
     }*/
  }
  
  func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
    if(collisionFeature){
      print("Update Contact Happened")
      contact.nodeA.opacity = 0
      contact.nodeB.opacity = 0
      /*let shapeNode: ShapeNode
       if(contact.nodeA.name == "cameraNode"){
       shapeNode = shapeManager.findShapeNode("\(contact.nodeB.name)")
       }else{
       shapeNode = shapeManager.findShapeNode("\(contact.nodeA.name)")
       }
       if(shapeNode.isDestination()){
       
       }else{
       shapeNode.setHidden(true)
       }*/
    }
  }
  
  //Function to setup the view and setup the AR Scene including options
  func setupView() {
    scnView = self.view as! ARSCNView
    scnView.showsStatistics = true
    scnView.autoenablesDefaultLighting = true
    scnView.delegate = self
    scnView.session.delegate = self
    scnView.isPlaying = true
    scnView.debugOptions = []
    mapTable.isHidden = true //hide the map list until 'Load Map' is clicked
    filterSlider.isContinuous = false
    toggleSliderUI(true, reset: true) //hide the radius search UI, reset values as we are initializating
    //scnView.debugOptions = ARSCNDebugOptions.showFeaturePoints
    //scnView.debugOptions = ARSCNDebugOptions.showWorldOrigin
  }
  
  //Function to setup AR Scene
  func setupScene() {
    scnScene = SCNScene()
    scnView.scene = scnScene
    
    scnView.scene.physicsWorld.contactDelegate = self
    
    ptViz = FeaturePointVisualizer(inputScene: scnScene);
    ptViz?.enableFeaturePoints()
    
    if let camera: SCNNode = scnView?.pointOfView {
      camManager = CameraManager(scene: scnScene, cam: camera)
    }
    setupCollisions()
    
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scnView.frame = view.bounds
  }
  
  
  // MARK: - PNDelegate functions
  
  //Receive a pose update when a new pose is calculated
  func onPose(_ outputPose: matrix_float4x4, _ arkitPose: matrix_float4x4) -> Void {
    
  }
  
  //Receive a status update when the status changes
  func onStatusChange(_ prevStatus: LibPlacenote.MappingStatus, _ currStatus: LibPlacenote.MappingStatus) {
    if prevStatus != LibPlacenote.MappingStatus.running && currStatus == LibPlacenote.MappingStatus.running { //just localized draw shapes you've retrieved
      print ("Just localized, drawing view")
      shapeManager.loadPath(path: selectedPath, parent: scnScene.rootNode) //just localized redraw the shapes
      if mappingStarted {
        statusLabel.text = "Tap anywhere to add Shapes, Move Slowly"
      }
      else if localizationStarted {
        statusLabel.text = "Map Found!"
      }
      tapRecognizer?.isEnabled = true
      
      //As you are localized, the camera has been moved to match that of Placenote's Map. Transform the planes
      //currently being drawn from the arkit frame of reference to the Placenote map's frame of reference.
      for (_, node) in planesVizNodes {
        node.transform = LibPlacenote.instance.processPose(pose: node.transform);
      }
    }
    
    if prevStatus == LibPlacenote.MappingStatus.running && currStatus != LibPlacenote.MappingStatus.running { //just lost localization
      print ("Just lost")
      if mappingStarted {
        statusLabel.text = "Moved too fast. Map Lost"
      }
      tapRecognizer?.isEnabled = false
      
    }
    
  }
  
  //Receive list of maps after it is retrieved. This is only fired when fetchMapList is called (see updateMapTable())
  func onMapList(success: Bool, mapList: [String: LibPlacenote.MapMetadata]) -> Void {
    maps.removeAll()
    if (!success) {
      print ("failed to fetch map list")
      statusLabel.text = "Map List not retrieved"
      return
    }
    
    //Cycle through the maplist and create a database of all the maps (place.key) and its metadata (place.value)
    for place in mapList {
      maps.append((place.key, place.value))
    }
    
    statusLabel.text = "Map List"
    self.mapTable.reloadData() //reads from maps array (see: tableView functions)
    self.mapTable.isHidden = false
    self.toggleSliderUI(false, reset: false)
    self.tapRecognizer?.isEnabled = false
  }
  
  // MARK: - UI functions
  
  @IBAction func newSaveMapButton(_ sender: Any) {
    
    if (trackingStarted && !mappingStarted) { //ARKit is enabled, start mapping
      mappingStarted = true
      
      LibPlacenote.instance.stopSession()
      
      LibPlacenote.instance.startSession()
      
      if (reportDebug) {
        LibPlacenote.instance.startReportRecord(uploadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
          if (completed) {
            self.statusLabel.text = "Dataset Upload Complete"
            self.fileTransferLabel.text = ""
          } else if (faulted) {
            self.statusLabel.text = "Dataset Upload Faulted"
            self.fileTransferLabel.text = ""
          } else {
            self.fileTransferLabel.text = "Dataset Upload: " + String(format: "%.3f", percentage) + "/1.0"
          }
        })
        print ("Started Debug Report")
      }
      
      localizationStarted = false
      pickMapButton.setTitle("Load Map", for: .normal)
      newMapButton.setTitle("Save Map", for: .normal)
      statusLabel.text = "Mapping: Tap to add shapes!"
      tapRecognizer?.isEnabled = true
      mapTable.isHidden = true
      toggleSliderUI(true, reset: false)
      toggleMappingUI(false)
      shapeManager.clearShapes() //creating new map, remove old shapes.
    }
    else if (mappingStarted) { //mapping been running, save map
      print("Saving Map")
      statusLabel.text = "Saving Map"
      mappingStarted = false
      LibPlacenote.instance.saveMap(
        savedCb: {(mapId: String?) -> Void in
          if (mapId != nil) {
            self.statusLabel.text = "Saved Id: " + mapId! //update UI
            LibPlacenote.instance.stopSession()
            
            let metadata = LibPlacenote.MapMetadataSettable()
            metadata.name = RandomName.Get()
            self.statusLabel.text = "Saved Map: " + metadata.name! //update UI
            
            if (self.lastLocation != nil) {
              metadata.location = LibPlacenote.MapLocation()
              metadata.location!.latitude = self.lastLocation!.coordinate.latitude
              metadata.location!.longitude = self.lastLocation!.coordinate.longitude
              metadata.location!.altitude = self.lastLocation!.altitude
            }
            var userdata: [String:Any] = [:]
            userdata["shapeArray"] = self.shapeManager.getShapeArray()
            metadata.userdata = userdata
            
            if (!LibPlacenote.instance.setMapMetadata(mapId: mapId!, metadata: metadata, metadataSavedCb: {(success: Bool) -> Void in})) {
              print ("Failed to set map metadata")
            }
            self.planeDetSelection.isOn = false
            self.planeDetection = false
            self.configureSession()
          } else {
            NSLog("Failed to save map")
          }
      },
        uploadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
          if (completed) {
            print ("Uploaded!")
            self.fileTransferLabel.text = ""
          } else if (faulted) {
            print ("Couldnt upload map")
          } else {
            print ("Progress: " + percentage.description)
            self.fileTransferLabel.text = "Map Upload: " + String(format: "%.3f", percentage) + "/1.0"
          }
      }
      )
      newMapButton.setTitle("New Map", for: .normal)
      pickMapButton.setTitle("Load Map", for: .normal)
      tapRecognizer?.isEnabled = false
      localizationStarted = false
      toggleMappingUI(true) //hide mapping UI
    }
  }
  
  @IBAction func pickMap(_ sender: Any) {
    
    if (localizationStarted) { // currently a map is loaded. StopSession and clearView
      shapeManager.clearShapes()
      ptViz?.reset()
      LibPlacenote.instance.stopSession()
      localizationStarted = false
      mappingStarted = false
      pickMapButton.setTitle("Load Map", for: .normal)
      newMapButton.setTitle("New Map", for: .normal)
      statusLabel.text = "Cleared"
      toggleMappingUI(true) //hided mapping options
      planeDetSelection.isOn = false
      planeDetection = false
      configureSession()
      return
    }
    
    if (mapTable.isHidden) { //fetch map list and show table of maps
      updateMapTable()
      pickMapButton.setTitle("Cancel", for: .normal)
      newMapButton.isEnabled = false
      statusLabel.text = "Fetching Map List"
      toggleSliderUI(true, reset: true)
    }
    else { //map load/localization session cancelled
      mapTable.isHidden = true
      toggleSliderUI(true, reset: false)
      pickMapButton.setTitle("Load Map", for: .normal)
      newMapButton.isEnabled = true
      statusLabel.text = "Map Load cancelled"
    }
  }
  
  @IBAction func onShowFeatureChange(_ sender: Any) {
    showFeatures = !showFeatures
    if (showFeatures) {
      ptViz?.enableFeaturePoints()
    }
    else {
      ptViz?.disableFeaturePoints()
    }
  }
    
    @IBAction func toggleCreatorMode(_ sender: Any) {
        creationMode = !creationMode
        planeDetLabel.isHidden = creationMode
        planeDetSelection.isHidden = creationMode
        showPNLabel.isHidden = creationMode
        showPNSelection.isHidden = creationMode
        deleteNodeLabel.isHidden = creationMode
        deleteNodeSelection.isHidden = creationMode
        nodeTypeLabel.isHidden = creationMode
        nodeTypeSelection.isHidden = creationMode
        levelLabel.isHidden = creationMode
        levelUpButton.isHidden = creationMode
        levelDownButton.isHidden = creationMode
      collisionFeature = !collisionFeature
      if(collisionFeature){
        createCameraNode()
      }else{
        cameraNode.removeFromParentNode()
        shapeManager.resetArrayColors()
      }
      print("toggle Collision")
      print(collisionFeature)
    }
    
    @IBAction func increaseLevel(_ sender: Any) {
        shapeManager.changeLevel(0.1);
    }
    
    @IBAction func decreaseLevel(_ sender: Any) {
        shapeManager.changeLevel(-0.1)
    }
    
    
  @IBAction func onDistanceFilterChange(_ sender: UISlider) {
    let currentValue = Float(sender.value)*maxRadiusSearch
    filterLabel1.text = String.localizedStringWithFormat("Distance filter: %.2f km", currentValue/1000.0)
    currRadiusSearch = currentValue
    updateMapTable(radius: currRadiusSearch)
  }
  @IBAction func nodeTypeDetection(_ sender: UISegmentedControl) {
    // 0 = start, 1 = arrow, 2 = destination
    selectedNodeType = sender.selectedSegmentIndex
    print("Selected Segment: \(selectedNodeType)")
  }
  
  @IBAction func onPlaneDetectionOnOff(_ sender: Any) {
    planeDetection = !planeDetection
    configureSession()
  }
  
  @IBAction func deleteNodesOnOff(_ sender: Any) {
    deleteNode = !deleteNode
  }
  
  @IBAction func pathDetection(_ sender: UISegmentedControl) {
    // 0 = path 1, 1 = path 2, 2 = path 3
    selectedPath = sender.selectedSegmentIndex
    print("Selected Path: \(selectedPath + 1)")
    shapeManager.loadPath(path: selectedPath, parent: scnScene.rootNode)
  }
  
  func configureSession() {
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    configuration.worldAlignment = ARWorldTrackingConfiguration.WorldAlignment.gravity //TODO: Maybe not heading?
    
    if (planeDetection) {
      if #available(iOS 11.3, *) {
        configuration.planeDetection = [.horizontal, .vertical]
      } else {
        configuration.planeDetection = [.horizontal]
      }
    }
    else {
      for (_, node) in planesVizNodes {
        node.removeFromParentNode()
      }
      for (anchor) in planesVizAnchors { //remove anchors because in iOS versions <11.3, the anchors are not automatically removed when plane detection is turned off.
        scnView.session.remove(anchor: anchor)
      }
      planesVizNodes.removeAll()
      configuration.planeDetection = []
    }
    // Run the view's session
    scnView.session.run(configuration)
  }
  
  /*@IBAction func toggleCollision(_ sender: Any) {
   collisionFeature = !collisionFeature
   print("toggle Collision")
   print(collisionFeature)
   }*/
  func toggleSliderUI (_ on: Bool, reset: Bool) {
    filterSlider.isHidden = on
    filterLabel1.isHidden = on
    filterLabel2.isHidden = on
    if (reset) {
      filterSlider.value = 1.0
      filterLabel1.text = "Distance slider: Off"
    }
  }
  
  func toggleMappingUI(_ on: Bool) {
    planeDetLabel.isHidden = on
    planeDetSelection.isHidden = on
    showPNLabel.isHidden = on
    showPNSelection.isHidden = on
    deleteNodeLabel.isHidden = on
    deleteNodeSelection.isHidden = on
    nodeTypeLabel.isHidden = on
    nodeTypeSelection.isHidden = on
    pathLabel.isHidden = on
    pathSelection.isHidden = on
    levelLabel.isHidden = on
    levelUpButton.isHidden = on
    levelDownButton.isHidden = on
    creatorModeLabel.isHidden = on
    creatorModeSelection.isHidden = on
  }
  
  // MARK: - UITableViewDelegate and UITableviewDataSource to manage retrieving, viewing, deleting and selecting maps on a TableView
  
  //Return count of maps
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    print(String(format: "Map size: %d", maps.count))
    return maps.count
  }
  
  //Label Map rows
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let map = self.maps[indexPath.row]
    var cell:UITableViewCell? = mapTable.dequeueReusableCell(withIdentifier: map.0)
    if cell==nil {
      cell =  UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: map.0)
    }
    cell?.textLabel?.text = map.0
    
    let name = map.1.name
    if name != nil && !name!.isEmpty {
      cell?.textLabel?.text = name
    }
    
    var subtitle = "Distance Unknown"
    
    let location = map.1.location
    
    if (lastLocation == nil) {
      subtitle = "User location unknown"
    } else if (location == nil) {
      subtitle = "Map location unknown"
    } else {
      let distance = lastLocation!.distance(from: CLLocation(
        latitude: location!.latitude,
        longitude: location!.longitude))
      subtitle = String(format: "Distance: %0.3fkm", distance / 1000)
    }
    
    cell?.detailTextLabel?.text = subtitle
    
    return cell!
  }
  
  //Map selected
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    print(String(format: "Retrieving row: %d", indexPath.row))
    print("Retrieving mapId: " + maps[indexPath.row].0)
    statusLabel.text = "Retrieving mapId: " + maps[indexPath.row].0
    
    LibPlacenote.instance.loadMap(mapId: maps[indexPath.row].0,
                                  downloadProgressCb: {(completed: Bool, faulted: Bool, percentage: Float) -> Void in
                                    if (completed) {
                                      self.mappingStarted = true //extending the map
                                      self.localizationStarted = true
                                      self.mapTable.isHidden = true
                                      self.pickMapButton.setTitle("Stop/Clear", for: .normal)
                                      self.newMapButton.isEnabled = true
                                      self.newMapButton.setTitle("Save Map", for: .normal)
                                      
                                      self.toggleMappingUI(false) //show mapping options UI
                                      self.toggleSliderUI(true, reset: true) //hide + reset UI for later
                                      
                                      //Using this method you can individual retrieve the metadata for a single map,
                                      //However, as we called a blanket fetchMapList before, it already acquired all the metadata for all maps
                                      //We'll just use that meta data for now.
                                      
                                      /*LibPlacenote.instance.getMapMetadata(mapId: self.maps[indexPath.row].0, getMetadataCb: {(success: Bool, metadata: LibPlacenote.MapMetadata) -> Void in
                                       let userdata = self.maps[indexPath.row].1.userdata as? [String:Any]
                                       if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: [String: String]]])) {
                                       self.statusLabel.text = "Map Loaded. Look Around"
                                       } else {
                                       self.statusLabel.text = "Map Loaded. Shape file not found"
                                       }
                                       LibPlacenote.instance.startSession(extend: true)
                                       })*/
                                      
                                      //Use metadata acquired from fetchMapList
                                      let userdata = self.maps[indexPath.row].1.userdata as? [String:Any]
                                      if (self.shapeManager.loadShapeArray(shapeArray: userdata?["shapeArray"] as? [[String: String]])) {
                                        self.statusLabel.text = "Map Loaded. Look Around"
                                      } else {
                                        self.statusLabel.text = "Map Loaded. Shape file not found"
                                      }
                                      LibPlacenote.instance.startSession(extend: true)
                                      
                                      
                                      if (self.reportDebug) {
                                        LibPlacenote.instance.startReportRecord (uploadProgressCb: ({(completed: Bool, faulted: Bool, percentage: Float) -> Void in
                                          if (completed) {
                                            self.statusLabel.text = "Dataset Upload Complete"
                                            self.fileTransferLabel.text = ""
                                          } else if (faulted) {
                                            self.statusLabel.text = "Dataset Upload Faulted"
                                            self.fileTransferLabel.text = ""
                                          } else {
                                            self.fileTransferLabel.text = "Dataset Upload: " + String(format: "%.3f", percentage) + "/1.0"
                                          }
                                        })
                                        )
                                        print ("Started Debug Report")
                                      }
                                      
                                      self.tapRecognizer?.isEnabled = true
                                    } else if (faulted) {
                                      print ("Couldnt load map: " + self.maps[indexPath.row].0)
                                      self.statusLabel.text = "Load error Map Id: " +  self.maps[indexPath.row].0
                                    } else {
                                      print ("Progress: " + percentage.description)
                                    }
    }
    )
  }
  
  //Make rows editable for deletion
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  //Delete Row and its corresponding map
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if (editingStyle == UITableViewCellEditingStyle.delete) {
      statusLabel.text = "Deleting Map:" + maps[indexPath.row].0
      LibPlacenote.instance.deleteMap(mapId: maps[indexPath.row].0, deletedCb: {(deleted: Bool) -> Void in
        if (deleted) {
          print("Deleting: " + self.maps[indexPath.row].0)
          self.statusLabel.text = "Deleted Map: " + self.maps[indexPath.row].0
          self.maps.remove(at: indexPath.row)
          self.mapTable.reloadData()
        }
        else {
          print ("Can't Delete: " + self.maps[indexPath.row].0)
          self.statusLabel.text = "Can't Delete: " + self.maps[indexPath.row].0
        }
      })
    }
  }
  
  func updateMapTable() {
    LibPlacenote.instance.fetchMapList(listCb: onMapList)
  }
  
  func updateMapTable(radius: Float) {
    LibPlacenote.instance.searchMaps(latitude: self.lastLocation!.coordinate.latitude, longitude: self.lastLocation!.coordinate.longitude, radius: Double(radius), listCb: onMapList)
  }
  
  @objc func handleTap(sender: UITapGestureRecognizer) {
    let tapLocation = sender.location(in: scnView)
    let hitResultsIns = scnView.hitTest(tapLocation, types: .featurePoint)
    let hitResultsNode = scnView.hitTest(tapLocation, options: [SCNHitTestOption.categoryBitMask : 1])
    if(!creationMode){
      if (hitResultsNode.count > 0) {
        let result = hitResultsNode[0] as! SCNHitTestResult
        let node = result.node
        guard let name = node.name else {
          let result = hitResultsIns.first
          print("Placed Node")
          let pose = LibPlacenote.instance.processPose(pose: result!.worldTransform)
          shapeManager.spawnShape(position: pose.position(), nodeType: selectedNodeType, path: selectedPath)
          return
        }
        print("hit: \(node.name)")
        let shapeNode = shapeManager.findShapeNode(node.name!)
        if deleteNode{
          print("Deleted Node")
          print(node.name)
          shapeManager.removeNode(node.name!)
          node.removeFromParentNode()
        }else{
          print("Rotate Node")
          //node.runAction(SCNAction.rotateBy(x: 0, y: (45 * .pi / 180), z: 0, duration: 0))
          shapeNode.rotateNode(x: 0, y: 45, z: 0)
        }
      }else if let result = hitResultsIns.first{
        print("Placed Node")
        let pose = LibPlacenote.instance.processPose(pose: result.worldTransform)
        shapeManager.spawnShape(position: pose.position(), nodeType: selectedNodeType, path: selectedPath)
      }
      
    }
  }
  
  
  // MARK: - ARSCNViewDelegate
  
  // Override to create and configure nodes for anchors added to the view's session.
  func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    let node = SCNNode()
    return node
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
    // Create a SceneKit plane to visualize the plane anchor using its position and extent.
    let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
    let planeNode = SCNNode(geometry: plane)
    planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
    
    node.transform = LibPlacenote.instance.processPose(pose: node.transform); //transform through
    planesVizNodes[anchor.identifier] = node; //keep track of plane nodes so you can move them once you localize to a new map.
    
    /*
     `SCNPlane` is vertically oriented in its local coordinate space, so
     rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
     */
    planeNode.eulerAngles.x = -.pi / 2
    
    // Make the plane visualization semitransparent to clearly show real-world placement.
    planeNode.opacity = 0.25
    
    /*
     Add the plane visualization to the ARKit-managed node so that it tracks
     changes in the plane anchor as plane estimation continues.
     */
    node.addChildNode(planeNode)
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
    guard let planeAnchor = anchor as?  ARPlaneAnchor,
      let planeNode = node.childNodes.first,
      let plane = planeNode.geometry as? SCNPlane
      else { return }
    
    // Plane estimation may shift the center of a plane relative to its anchor's transform.
    planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
    
    /*
     Plane estimation may extend the size of the plane, or combine previously detected
     planes into a larger one. In the latter case, `ARSCNView` automatically deletes the
     corresponding node for one plane, then calls this method to update the size of
     the remaining plane.
     */
    plane.width = CGFloat(planeAnchor.extent.x)
    plane.height = CGFloat(planeAnchor.extent.z)
    
    node.transform = LibPlacenote.instance.processPose(pose: node.transform)
  }
  
  // MARK: - ARSessionDelegate
  
  //Provides a newly captured camera image and accompanying AR information to the delegate.
  func session(_ session: ARSession, didUpdate: ARFrame) {
    let image: CVPixelBuffer = didUpdate.capturedImage
    let pose: matrix_float4x4 = didUpdate.camera.transform
    
    if (!LibPlacenote.instance.initialized()) {
      print("SDK is not initialized")
      return
    }
    
    if (mappingStarted || localizationStarted) {
      LibPlacenote.instance.setFrame(image: image, pose: pose)
    }
  }
  
  
  //Informs the delegate of changes to the quality of ARKit's device position tracking.
  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    var status = "Loading.."
    switch camera.trackingState {
    case ARCamera.TrackingState.notAvailable:
      status = "Not available"
    case ARCamera.TrackingState.limited(.excessiveMotion):
      status = "Excessive Motion."
    case ARCamera.TrackingState.limited(.insufficientFeatures):
      status = "Insufficient features"
    case ARCamera.TrackingState.limited(.initializing):
      status = "Initializing"
    case ARCamera.TrackingState.limited(.relocalizing):
      status = "Relocalizing"
    case ARCamera.TrackingState.normal:
      if (!trackingStarted) {
        trackingStarted = true
        print("ARKit Enabled, Start Mapping")
        newMapButton.isEnabled = true
        newMapButton.setTitle("New Map", for: .normal)
      }
      status = "Ready"
    }
    statusLabel.text = status
  }
  
  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    for (anchor) in anchors {
      planesVizAnchors.append(anchor)
    }
  }
  
  // MARK: - CLLocationManagerDelegate
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    lastLocation = locations.last
  }
}



