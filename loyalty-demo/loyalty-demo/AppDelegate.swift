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
    println("Starting up Loyalty app")
    application.applicationIconBadgeNumber = 0;
    
    var readAction = UIMutableUserNotificationAction()
    readAction.identifier = "READ_IDENTIFIER"
    readAction.title = "Read";
    readAction.activationMode = UIUserNotificationActivationMode.Foreground;
    readAction.destructive = true;
    readAction.authenticationRequired = true;
    
    var ignoreAction = UIMutableUserNotificationAction()
    ignoreAction.identifier = "IGNORE_IDENTIFIER";
    ignoreAction.title = "Ignore";
    ignoreAction.activationMode = UIUserNotificationActivationMode.Background
    ignoreAction.destructive = false;
    ignoreAction.authenticationRequired = false;
    
    var deleteAction = UIMutableUserNotificationAction()
    deleteAction.identifier = "DELETE_IDENTIFIER";
    deleteAction.title = "Delete";
    deleteAction.activationMode = UIUserNotificationActivationMode.Foreground;
    deleteAction.destructive = true;
    deleteAction.authenticationRequired = true;
    
    var messageCategory = UIMutableUserNotificationCategory()
    messageCategory.identifier = "MESSAGE_CATEGORY";
    messageCategory.setActions([readAction, ignoreAction, deleteAction], forContext:UIUserNotificationActionContext.Default)
    messageCategory.setActions([readAction, deleteAction], forContext:UIUserNotificationActionContext.Minimal)
    
    let categories = NSSet(array: [messageCategory])
    let types: UIUserNotificationType = .Badge | .Sound | .Alert;
    let mySettings = UIUserNotificationSettings(forTypes: types, categories: categories as Set<NSObject>)
    
    UIApplication.sharedApplication().registerForRemoteNotifications()
    UIApplication.sharedApplication().registerUserNotificationSettings(mySettings)
    
    if launchOptions != nil {
      let message = "\(launchOptions)"
      createMessage(message)
    }
    
 
    return true
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    var characterSet: NSCharacterSet = NSCharacterSet( charactersInString: "<>" )
    
    var deviceTokenString: String = ( deviceToken.description as NSString )
      .stringByTrimmingCharactersInSet( characterSet )
      .stringByReplacingOccurrencesOfString( " ", withString: "" ) as String
    
    let settings = NSUserDefaults.standardUserDefaults()
    let endpoint = settings.stringForKey("endpoint")
    println("deviceToken \(deviceTokenString)")
    self.snsService = SNSService(deviceId: deviceTokenString, endpoint: endpoint)
    if endpoint == nil {
      self.snsService.register({
        println("Registered with SNS")
        self.startBeaconKit()
      })
    } else {
      self.startBeaconKit()
    }
  }
  
  func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    println("Error registering for push notifications \(error)")
  }
  
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    application.applicationIconBadgeNumber = 0;
    
    let message = userInfo["message"] as! Dictionary<String, AnyObject>
    let topic = "Loyalty Discount"
    let payload = message["payload"] as! String
    
    if(UIApplication.sharedApplication().applicationState == UIApplicationState.Background) {
      var notification = UILocalNotification()
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
    let messageJSON = JSON(data: rawData!, options: nil, error: nil)
    let message = messageJSON["payload"].string
    if message != nil {
      let alertView = UIAlertView(title: "Message Recieved", message: message!, delegate: self, cancelButtonTitle: "Okay")
      alertView.show()
      println("Message Recieved \(message!)")
      return
    }
    println("Invalid Message Received")
  }
  
  func startBeaconKit(){
    var meshbluConfig = Dictionary<String, AnyObject>()
    let settings = NSUserDefaults.standardUserDefaults()
    let uuid = settings.stringForKey("uuid")
    let token = settings.stringForKey("token")
    
    meshbluConfig["uuid"] = uuid
    meshbluConfig["token"] = token
    println("UUID: \(uuid) TOKEN: \(token)")
    
    
    self.meshbluBeaconKit = MeshbluBeaconKit(meshbluConfig: meshbluConfig, delegate: self)
    self.meshbluBeaconKit.enableDebug()
    let beaconTypes = [
      "B9407F30-F5F8-466E-AFF9-25556B57FE6D":"Estimote Region",
      "CF593B78-DA79-4077-ABA3-940085DF45CA":"iBeaconModules.us"
    ]
    meshbluBeaconKit.start(beaconTypes)
  }
}

extension AppDelegate: MeshbluBeaconKitDelegate {
  
  func getMainControler() -> ViewController {
    let viewController:ViewController = window!.rootViewController as! ViewController
    return viewController
  }
  
  func updateMainViewWithMessage(message: String){
    let viewController = getMainControler()
//    println("Message is \(message)")
  }
  
  func proximityChanged(response: [String: AnyObject]) {
    println("Proximity Changed")
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
        println("Error messaging device with SNS \(error)")
      case let .Success(success):
        println("message succeeded")
      default:
        println("Neither failure or success")
      }
  
    }
  }
  
  func meshbluBeaconIsNotRegistered() {
    println("Meshblu Beacon Not Registered")
    self.meshbluBeaconKit.register()
  }
  
  func meshbluBeaconRegistrationSuccess(device: [String: AnyObject]) {
    println("Meshblu Registration Success \(device)")
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
    println("Meshblu Update with SNS \(meshbluUpdateProperties)")
    meshbluHttp.update(meshbluUpdateProperties, handler: { (result) -> () in
      switch result {
      case let .Failure(error):
        println("Error updating device with SNS \(error)")
      case let .Success(success):
        println("Update succeeded")
      default:
        println("Neither failure or success")
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

