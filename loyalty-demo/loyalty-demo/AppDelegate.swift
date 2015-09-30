//
//  AppDelegate.swift
//  loyalty-demo
//
//  Created by Octoblu on 6/15/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import UIKit
import CoreLocation
import MeshbluBeaconKit
import MeshbluKit
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MeshbluBeaconKitDelegate {

  var window: UIWindow?
  var meshbluBeaconKit : MeshbluBeaconKit!
  var snsService: SNSService!

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    print("Starting up Loyalty app")
    application.applicationIconBadgeNumber = 0;
    
    let readAction = UIMutableUserNotificationAction()
    readAction.identifier = "READ_IDENTIFIER"
    readAction.title = "Read";
    readAction.activationMode = UIUserNotificationActivationMode.Foreground;
    readAction.destructive = true;
    readAction.authenticationRequired = true;
    
    let ignoreAction = UIMutableUserNotificationAction()
    ignoreAction.identifier = "IGNORE_IDENTIFIER";
    ignoreAction.title = "Ignore";
    ignoreAction.activationMode = UIUserNotificationActivationMode.Background
    ignoreAction.destructive = false;
    ignoreAction.authenticationRequired = false;
    
    let deleteAction = UIMutableUserNotificationAction()
    deleteAction.identifier = "DELETE_IDENTIFIER";
    deleteAction.title = "Delete";
    deleteAction.activationMode = UIUserNotificationActivationMode.Foreground;
    deleteAction.destructive = true;
    deleteAction.authenticationRequired = true;
    
    let messageCategory = UIMutableUserNotificationCategory()
    messageCategory.identifier = "MESSAGE_CATEGORY";
    messageCategory.setActions([readAction, ignoreAction, deleteAction], forContext:UIUserNotificationActionContext.Default)
    messageCategory.setActions([readAction, deleteAction], forContext:UIUserNotificationActionContext.Minimal)
//    
//    let categories = NSSet(array: [messageCategory])
//    let types: UIUserNotificationType = .Badge | .Sound | .Alert;
//    let mySettings = UIUserNotificationSettings(forTypes: types, categories: categories as Set<NSObject>)
//    
//    UIApplication.sharedApplication().registerForRemoteNotifications()
//    UIApplication.sharedApplication().registerUserNotificationSettings(mySettings)
    
    
    
    let types: UIUserNotificationType = [.Alert, .Badge, .Sound]
    let categories = NSSet(array: [messageCategory]) as? Set<UIUserNotificationCategory>
    let settings = UIUserNotificationSettings(forTypes: types, categories: categories)
    
    UIApplication.sharedApplication().registerForRemoteNotifications()
    UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    
    if launchOptions != nil {
      let message = "\(launchOptions)"
      createMessage(message)
    }
    
 
    return true
  }
  
  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    let characterSet: NSCharacterSet = NSCharacterSet( charactersInString: "<>" )
    
    let deviceTokenString: String = ( deviceToken.description as NSString )
      .stringByTrimmingCharactersInSet( characterSet )
      .stringByReplacingOccurrencesOfString( " ", withString: "" ) as String
    
    let settings = NSUserDefaults.standardUserDefaults()
    let endpoint = settings.stringForKey("endpoint")
    print("deviceToken \(deviceTokenString)")
    self.snsService = SNSService(deviceId: deviceTokenString, endpoint: endpoint)
    if endpoint == nil {
      self.snsService.register({
        print("Registered with SNS")
        self.startBeaconKit()
      })
    } else {
      self.startBeaconKit()
    }
  }
  
  func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    print("Error registering for push notifications \(error)")
  }
  
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    application.applicationIconBadgeNumber = 0;
    
    let message = userInfo["message"] as! Dictionary<String, AnyObject>
    let topic = "Loyalty Discount"
    let payload = message["payload"] as! String
    
    if(UIApplication.sharedApplication().applicationState == UIApplicationState.Background) {
      let notification = UILocalNotification()
      notification.alertTitle = topic
      notification.alertBody = payload
      
      UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    } else {
      let alertView = UIAlertView(title: topic, message: payload, delegate: self, cancelButtonTitle: "Okay")
      alertView.show()
    }
  }
  
  func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
    if identifier == "READ_IDENTIFIER" {
      let message = "read"
      createMessage(message)
    }
    if identifier == "DELETE_IDENTIFIER" {
      let message = "delete"
      createMessage(message)
    }
    completionHandler();
  }
  
  func createMessage(rawMessage: String){
    let rawData = rawMessage.dataUsingEncoding(NSUTF8StringEncoding)
    let messageJSON = JSON(data: rawData!)
    let message = messageJSON["payload"].string
    if message != nil {
      let alertView = UIAlertView(title: "Message Recieved", message: message!, delegate: self, cancelButtonTitle: "Okay")
      alertView.show()
      print("Message Recieved \(message!)")
      return
    }
    print("Invalid Message Received")
  }
  
  func startBeaconKit(){
    var meshbluConfig = Dictionary<String, AnyObject>()
    let settings = NSUserDefaults.standardUserDefaults()
    let uuid = settings.stringForKey("uuid")
    let token = settings.stringForKey("token")
    
    meshbluConfig["uuid"] = uuid
    meshbluConfig["token"] = token
    print("UUID: \(uuid) TOKEN: \(token)")
    
    
    self.meshbluBeaconKit = MeshbluBeaconKit(meshbluConfig: meshbluConfig, delegate: self)
    self.meshbluBeaconKit.enableDebug()
    let beaconTypes = [
      "B9407F30-F5F8-466E-AFF9-25556B57FE6D":"Estimote Region",
      "CF593B78-DA79-4077-ABA3-940085DF45CA":"iBeaconModules.us"
    ]
    meshbluBeaconKit.start(beaconTypes)
  }

  
  func getMainControler() -> ViewController {
    let viewController:ViewController = window!.rootViewController as! ViewController
    return viewController
  }
  
  func updateMainViewWithMessage(message: String){
    let viewController = getMainControler()
//    println("Message is \(message)")
  }
  
  func proximityChanged(response: [String: AnyObject]) {
    print("Proximity Changed")
    var message = ""
    let proximity = response["proximity"] as! [String: AnyObject]
    switch(proximity["code"] as! Int) {
    case 3:
      message = "Far away from beacon"
    case 2:
      message = "You are near the beacon"
    case 1:
      message = "Immediate proximity to beacon"
    case 0:
      message = "No beacons are nearby"
    default:
      message = "No beacons are nearby"
    }
    
    let viewController = getMainControler()
    self.updateMainViewWithMessage(message)
    self.meshbluBeaconKit.sendLocationUpdate(response) {
      (result) -> () in
      switch result {
      case let .Failure(error):
        print("Error messaging device with SNS \(error)")
      case .Success(_):
        print("message succeeded")
      default:
        print("Neither failure or success")
      }
  
    }
  }
  
  func meshbluBeaconIsNotRegistered() {
    print("Meshblu Beacon Not Registered")
    self.meshbluBeaconKit.register()
  }
  
  func meshbluBeaconRegistrationSuccess(device: [String: AnyObject]) {
    print("Meshblu Registration Success \(device)")
    let settings = NSUserDefaults.standardUserDefaults()
    let uuid = device["uuid"] as! String
    let token = device["token"] as! String
    
    settings.setObject(uuid, forKey: "uuid")
    settings.setObject(token, forKey: "token")
    
    let endpoint = settings.stringForKey("endpoint")!
  
    let meshbluHttp = meshbluBeaconKit.getMeshbluClient()
    let meshbluUpdateProperties : [String: AnyObject] = [
      "meshblu.messageHooks": [
        [
          "url": "https://sns.octoblu.com/messages",
          "method": "POST",
          "headers": [
            "X-SNS-ARN": self.snsService.arn,
            "X-SNS-Endpoint": endpoint,
            "X-SNS-Platform": "IOS",
            "X-SNS-Sandbox": "true"
          ]
        ]
      ]
    ]
    print("Meshblu Update with SNS \(meshbluUpdateProperties)")
    meshbluHttp.update(meshbluUpdateProperties, handler: { (result) -> () in
      switch result {
      case let .Failure(error):
        print("Error updating device with SNS \(error)")
      case .Success(_):
        print("Update succeeded")
      default:
        print("Neither failure or success")
      }
    })
  }
  
  func beaconEnteredRegion() {
    self.updateMainViewWithMessage("Beacon Entered Region")
  }
  
  func beaconExitedRegion() {
    self.updateMainViewWithMessage("Beacon Exitied Region")
  }
  
}

