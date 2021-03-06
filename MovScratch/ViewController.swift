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
  @IBOutlet weak var loopCountLabel: UILabel!
  
  var loopCount: Int = 1002231
  
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
    progressView.expand = false
  }
  
  func playerViewWillBeginSeeking() {
    progressView.expand = true
  }
  
  func playerViewDidChangePosition(_ currentPosition: Double) {
    progressView.position = currentPosition
  }
  
  func playerViewDidLoop() {
    loopCount += 1
    let t = CATransition.init()
    t.type = kCATransitionPush
    t.subtype = kCATransitionFromBottom
    t.duration = 0.2
    loopCountLabel.layer.add(t, forKey: nil)
    loopCountLabel.text = String(loopCount)
  }
  
  func playerViewDidScratchPrevious() {
    loopCount += 1
    let t = CATransition.init()
    t.type = kCATransitionPush
    t.subtype = kCATransitionFromBottom
    t.duration = 0.2
    loopCountLabel.layer.add(t, forKey: nil)
    loopCountLabel.text = String(loopCount)
  }

}

