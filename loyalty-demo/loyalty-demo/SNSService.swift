//
//  SNSService.swift
//  loyalty-demo
//
//  Created by Peter DeMartini on 6/18/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Result

class SNSService {
  var manager : Alamofire.Manager!
  var deviceId: String!
  var arn = "arn:aws:sns:us-west-2:822069890720:app/APNS_SANDBOX/LoyaltyDemo"
  var endpoint: String!
  
  init(deviceId: String){
    self.setManager()
  }
  
  func setManager(){
    var defaultHeaders = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
    defaultHeaders["X-SNS-Device"] = self.deviceId
    defaultHeaders["X-SNS-ARN"] = self.arn
    defaultHeaders["X-SNS-Platform"] = "IOS"
    defaultHeaders["X-SNS-Sandbox"] = true
    if self.endpoint != nil {
      let settings = NSUserDefaults.standardUserDefaults()
      settings.setObject(endpoint, forKey: "endpoint") 
      defaultHeaders["X-SNS-Endpoint"] = endpoint
    }
    println("Setting headers \(defaultHeaders)")
    
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.HTTPAdditionalHeaders = defaultHeaders
    self.manager = Alamofire.Manager(configuration: configuration)
  }
  
  func register(done: () -> ()){
    self.post("/devices", parameters: [:], handler: { (result) -> () in
      switch result {
      case let .Failure(error):
        println("Error registering device with SNS \(error)")
      case let .Success(success):
        let json = success.value
        var data = Dictionary<String, AnyObject>()
        self.endpoint = json["endpoint"].stringValue
        self.setManager()
      default:
        println("Neither failure or success")
      }
      done()
    })
  }
  
  func post(path : String, parameters : [String: AnyObject], handler: (Result<JSON, NSError>) -> ()){
    let urlComponent = NSURLComponents()
    urlComponent.port = 443
    urlComponent.host = "sns.octoblu.com"
    urlComponent.scheme = urlComponent.port == 443 ? "https" : "http"
    urlComponent.path = path
    let url = urlComponent.string!
    
    println("About to request")
    
    self.manager.request(.POST, url, parameters: parameters, encoding: .JSON)
      .responseJSON { (request, response, data, error) in
        let json = JSON(data!)
        handler(Result(value: json))
    }
  }
}

