//
//  ViewController.swift
//  loyalty-demo
//
//  Created by Octoblu on 6/15/15.
//  Copyright (c) 2015 Octoblu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIWebViewDelegate {

  @IBOutlet var kioskWebView: UIWebView!
  let uuid = "6a605fd3-843a-4c2c-8776-e70c7bd23bef"
  let token = "34efdd94193aa9f13fe982a422ee934c946bca08"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let url = NSURL(string: "http://kiosk.octoblu.com/kiosk.html#!\(self.uuid)/\(self.token)")
    let urlRequest = NSURLRequest(URL: url!)
    self.kioskWebView.loadRequest(urlRequest)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

