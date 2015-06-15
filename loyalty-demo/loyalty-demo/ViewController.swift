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
  
  let uuid = "c3f31834-8e12-46d2-b159-62cbea2d3f18"
  let token = "962f54fe236271a01f50a82b5e389bdde652e441"
  
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

