//
//  MeshbluKit.swift
//  Pods
//
//  Created by Octoblu on 6/1/15.
//
//

import Foundation
import Alamofire
import SwiftyJSON
import Result

public class MeshbluHttpRequester {
  var meshbluConfig : [String: AnyObject]
  var manager : Alamofire.Manager
  
  public init(meshbluConfig: [String: AnyObject]){
    self.meshbluConfig = meshbluConfig
    if (self.meshbluConfig["port"] == nil){
      self.meshbluConfig["port"] = 443
    }
    if (self.meshbluConfig["host"] == nil){
      self.meshbluConfig["host"] = "meshblu.octoblu.com"
    }
    var defaultHeaders = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
    defaultHeaders["X-Meshblu-UUID"] = self.meshbluConfig["uuid"]
    defaultHeaders["X-Meshblu-Token"] = self.meshbluConfig["token"]
    
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.HTTPAdditionalHeaders = defaultHeaders
    
    self.manager = Alamofire.Manager(configuration: configuration)
  }
  
  public func post(path : String, parameters : [String: AnyObject], handler: (Result<JSON, NSError>) -> ()){
    let urlComponent = NSURLComponents()
    urlComponent.port = self.meshbluConfig["port"] as? NSNumber
    urlComponent.host = self.meshbluConfig["host"] as? String
    urlComponent.scheme = urlComponent.port == 443 ? "https" : "http"
    urlComponent.path = path
    let url = urlComponent.string!
    
    println("About to request")
    
    self.manager.request(.POST, url, parameters: parameters, encoding: .JSON)
      .responseJSON { (request, response, data, error) in
        let json = JSON(data!)
        handler(Result(value: json))
    }
  }}

@objc (MeshbluHttp) public class MeshbluHttp {
  var httpRequester : MeshbluHttpRequester
  
  public init(meshbluConfig: [String: AnyObject]) {
    self.httpRequester = MeshbluHttpRequester(meshbluConfig: meshbluConfig)
  }
  
  public init(requester: MeshbluHttpRequester){
    self.httpRequester = requester
  }
  
  public func register(device: [String: AnyObject], handler: (Result<JSON, NSError>) -> ()){
    self.httpRequester.post("/devices", parameters: device) {
      (result) -> () in
        
      handler(result)
    }
  }
  
  public func message(message: [String: AnyObject], handler: (Result<JSON, NSError>) -> ()){
    self.httpRequester.post("/messages", parameters: message) {
      (result) -> () in
      
      handler(result)
    }
  }

}