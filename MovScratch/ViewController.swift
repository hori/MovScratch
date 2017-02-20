//
//  ViewController.swift
//  MovScratch
//
//  Created by hor on 2017/02/08.
//  Copyright © 2017年 hor. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

class ViewController: UIViewController {

  @IBOutlet weak var playerView: PlayerView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let path = Bundle.main.path(forResource: "snowboarding_480p", ofType: "m4v")
    playerView.asset = AVURLAsset(url: URL(fileURLWithPath: path!))
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}


