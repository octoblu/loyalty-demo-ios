//
//  MeshbluBeaconKit.swift
//  Pods
//
//  Created by Octoblu on 6/1/15.
//
//

import Foundation
import CoreLocation
import MeshbluKit
import SwiftyJSON
import Result
import Dollar

@objc public protocol MeshbluBeaconKitDelegate {
  optional  func proximityChanged(response: [String: AnyObject])
  optional  func beaconEnteredRegion()
  optional  func beaconExitedRegion()
  optional  func meshbluBeaconIsUnregistered()
  optional  func meshbluBeaconRegistrationSuccess(device: [String: AnyObject])
  optional  func meshbluBeaconRegistrationFailure(error: NSError)
}

@objc (MeshbluBeaconKit) public class MeshbluBeaconKit: NSObject, CLLocationManagerDelegate {
  
  var lastProximity = CLProximity.Unknown
  public var beaconUuid = ""
  public var meshbluConfig : [String: AnyObject]?
  var meshbluHttp : MeshbluHttp?
  var delegate: MeshbluBeaconKitDelegate?
  let locationManager = CLLocationManager()
  
  public init(meshbluConfig: [String: AnyObject]) {
    self.meshbluConfig = meshbluConfig
    self.meshbluHttp = MeshbluHttp(meshbluConfig: meshbluConfig)
    super.init()
  }
  
  public init(meshbluHttp: MeshbluHttp) {
    self.meshbluConfig = [:]
    self.meshbluHttp = meshbluHttp
    super.init()
  }
  
  public func start(beaconUuid: String, delegate: MeshbluBeaconKitDelegate) {
    self.beaconUuid = beaconUuid
    self.delegate = delegate
    
    let beaconIdentifier = "iBeaconModules.us"
    let beaconUUID:NSUUID? = NSUUID(UUIDString: self.beaconUuid)
    let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID:beaconUUID, identifier: beaconIdentifier)
    
    if(locationManager.respondsToSelector("requestAlwaysAuthorization")) {
      if CLLocationManager.authorizationStatus() == .NotDetermined {
        locationManager.requestAlwaysAuthorization()
      }
    }
    
    locationManager.delegate = self
    locationManager.pausesLocationUpdatesAutomatically = false
    
    locationManager.startMonitoringForRegion(beaconRegion)
    locationManager.startRangingBeaconsInRegion(beaconRegion)
    if CLLocationManager.locationServicesEnabled() {
      locationManager.startUpdatingLocation()
      locationManager.startUpdatingHeading()
    }
    
    if (self.meshbluConfig!["uuid"] == nil) {
      self.delegate?.meshbluBeaconIsUnregistered!()
    }
  }
  
  public func register() {
    let device = ["type": "device:beacon-blu", "online" : "true"]
    
    self.meshbluHttp!.register(device) { (result) -> () in
      switch result {
      case let .Failure(error):
        self.delegate?.meshbluBeaconRegistrationFailure!(result.error!)
      case let .Success(success):
        let json = success.value
        var data = Dictionary<String, AnyObject>()
        data["uuid"] = json["uuid"].stringValue
        data["token"] = json["token"].stringValue
        self.delegate?.meshbluBeaconRegistrationSuccess!(data)
      }
    }
  }
  
  public func locationManager(manager: CLLocationManager!, didRangeBeacons beacons:[AnyObject]!, inRegion region: CLBeaconRegion!) {
    var code = 0
    var message = "Unknown"
    var nearestBeacon = CLBeacon()
    
    if(beacons.count > 0) {
      nearestBeacon = beacons[0] as! CLBeacon
    }
      
    if(nearestBeacon.proximity == lastProximity) {
      return;
    }

    lastProximity = nearestBeacon.proximity;
      
    switch nearestBeacon.proximity {
    case CLProximity.Far:
      code = 3
      message = "Far"
    case CLProximity.Near:
      code = 2
      message = "Near"
    case CLProximity.Immediate:
      code = 1
      message = "Immediate"
    case CLProximity.Unknown:
      code = 0
      message = "Unknown"
    }
    
    println(self.locationManager.location)
    
    let location = self.locationManager.location
    let heading = self.locationManager.heading
    
    let dateFor = NSDateFormatter()
    dateFor.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    var response : [String: AnyObject] = [
      "platform": "ios",
      "version": NSProcessInfo.processInfo().operatingSystemVersionString,
      "libraryVersion": MeshbluBeaconKit.version(),
      "beacon": [
        "uuid": nearestBeacon.proximityUUID.UUIDString,
        "major": nearestBeacon.major,
        "minor": nearestBeacon.minor
      ],
      "proximity": [
        "message": message,
        "code": code,
        "rssi": nearestBeacon.rssi,
        "accuracy": nearestBeacon.accuracy,
        "timestamp": dateFor.stringFromDate(NSDate())
      ]
    ]
    
    if (location != nil) {
      var level = 0
      if (location.floor != nil) {
        level = location.floor.level
      }

      response["location"] = [
        "coordinates": [location.coordinate.latitude, location.coordinate.longitude],
        "altitude": location.altitude,
        "floor": level,
        "horizontalAccuracy": location.horizontalAccuracy,
        "verticalAccuracy": location.verticalAccuracy,
        "timestamp": dateFor.stringFromDate(location.timestamp)
      ]
    }
    
    if (heading != nil) {
      response["heading"] = [
        "magneticHeading": heading.magneticHeading,
        "trueHeading": heading.trueHeading,
        "headingAccuracy": heading.headingAccuracy,
        "timestamp": dateFor.stringFromDate(heading.timestamp)
      ]
    }
    
    println("Sending response: \(response)")

    self.delegate?.proximityChanged!(response)
  }
  
  public func locationManager(manager: CLLocationManager!,
    didChangeAuthorizationStatus status: CLAuthorizationStatus)
  {
    if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
      manager.startUpdatingLocation()
      manager.startUpdatingHeading()
    }
  }
  
  public func locationManager(manager: CLLocationManager!,
    didEnterRegion region: CLRegion!) {
      manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
      manager.startUpdatingLocation()
      
      self.delegate?.beaconEnteredRegion!()
  }
  
  public func locationManager(manager: CLLocationManager!,
    didExitRegion region: CLRegion!) {
      manager.stopRangingBeaconsInRegion(region as! CLBeaconRegion)
      manager.stopUpdatingLocation()
      
      self.delegate?.beaconExitedRegion!()
  }
  
  public func sendLocationUpdate(payload: [String: AnyObject], handler: (Result<JSON, NSError>) -> ()){
    var message : [String: AnyObject] = [
      "devices" : ["*"],
      "payload" : payload,
      "topic" : "location_update"
    ]
    
    self.meshbluHttp!.message(message) {
      (result) -> () in
      handler(result)
      NSLog("Message Sent: \(message)")
    }
  }
}