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
  @IBOutlet weak var progressView: ProgressView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let path = Bundle.main.path(forResource: "snowboarding_480p", ofType: "m4v")
    playerView.asset = AVURLAsset(url: URL(fileURLWithPath: path!))
    playerView.delegate = self
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

extension ViewController {
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
}

// MARK: PlayerViewDelegate

extension ViewController: PlayerViewDelegate {
  func playerViewDidEndSeeking() {
    print("playerViewDidEndSeeking")
    progressView.expand = false
  }
  
  func playerViewWillBeginSeeking() {
    print("playerViewWillBeginSeeking")
    progressView.expand = true
  }
  
  func playerViewDidChangePosition(_ currentPosition: Double) {
    progressView.position = currentPosition
  }
}

