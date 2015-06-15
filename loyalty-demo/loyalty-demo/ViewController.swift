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
  
  let uuid = "297a484a-ba82-48a0-b303-5d288f25530d"
  let token = "b7627358dfc0c8cbcdfa2699bdb28032104d03a0"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let url = NSURL(string: "https://kiosk.octoblu.com/kiosk.html#!\(self.uuid)/\(self.token)")
    var urlRequest = NSURLRequest(URL: url!)
    self.kioskWebView.loadRequest(urlRequest)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

