//
//  PlayerView.swift
//  MovScratch
//
//  Created by hor on 2017/02/09.
//  Copyright © 2017年 hor. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class PlayerView: UIView {
  
  let seekRate: Int = 4
  let decelerationRate: CGFloat = 0.8

  var player: AVPlayer!
  var videoFrameCount: Int!
  var scrollView: UIScrollView!

  var lastSeekedAt: Double = 0
  var lastSeekedPosition: Double = 0
  var isMomentumSeeking: Bool = false

  let generator = UINotificationFeedbackGenerator()

  var asset: AVAsset! {
    didSet {
      guard let asset = self.asset else { return }
      videoFrameCount = self.videoFrameCount(asset: asset)
      self.setupPlayer(asset: asset)
      self.setupScrollView(width: videoFrameCount*seekRate)
      player.play()
    }
  }

  var playerLayer: AVPlayerLayer {
    return layer as! AVPlayerLayer
  }

  override static var layerClass: AnyClass {
    return AVPlayerLayer.self
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    scrollView = UIScrollView(frame: self.superview!.bounds)
    self.addSubview(scrollView)
  }
  
  // MARK: - Setup
  fileprivate func setupScrollView(width: Int) {
    scrollView.contentSize = CGSize(width: CGFloat(width), height: scrollView.bounds.size.height)
    scrollView.contentInset.left = scrollView.bounds.size.width/2
    scrollView.contentInset.right = scrollView.bounds.size.width/2
    scrollView.delegate = self
    scrollView.bounces = false
    scrollView.decelerationRate = decelerationRate
    
    // sync scrollview
    let time : CMTime = CMTimeMakeWithSeconds(0.1, Int32(NSEC_PER_SEC))
    player.addPeriodicTimeObserver(forInterval: time, queue: nil) { [unowned self] (time) -> Void in
      guard self.player.rate != 0 else {return}
      let index = self.frameIndexToSeek(cmTime: self.player.currentTime())
      self.scrollView.contentOffset.x = CGFloat(Double(index*self.seekRate) - Double(self.scrollView.contentInset.right))
    }
  }
  
  fileprivate func setupPlayer(asset: AVAsset) {
    player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
    playerLayer.player = player
    
    // loop video
    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil, using: { (_) in
      DispatchQueue.main.async {
        self.player?.seek(to: kCMTimeZero)
        self.player?.play()
      }
    })
  }

  // MARK: - To seek

  fileprivate func videoFrameCount(asset: AVAsset) -> Int {
    guard let track = asset.tracks.first else { return 0 }
    let fps = track.nominalFrameRate
    let sec = Float(CMTimeGetSeconds(asset.duration))
    return Int (fps * sec)
  }

  fileprivate func cmTimeToSeek(index: Int) -> CMTime {
    let seekTo = (Double(index/seekRate) / Double(videoFrameCount - 1)) * CMTimeGetSeconds(asset.duration)
    if seekTo < 0 {return kCMTimeZero}
    if seekTo > CMTimeGetSeconds(asset.duration) {return asset.duration}
    return CMTimeMakeWithSeconds(seekTo, Int32(NSEC_PER_SEC))
  }
  
  fileprivate func frameIndexToSeek(cmTime: CMTime) -> Int {
    let seekTo = Int((CMTimeGetSeconds(cmTime) / CMTimeGetSeconds(asset.duration)) * Double(videoFrameCount))
    if seekTo < 0 {return 0}
    if seekTo > (videoFrameCount - 1)  {return (videoFrameCount - 1)}
    return seekTo
  }

}

// MARK: - UIScrollViewDelegate
extension PlayerView: UIScrollViewDelegate {
  
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let index = Int(scrollView.contentOffset.x + (scrollView.bounds.width/2))
    if player.rate == 0 {
      let toSeek = self.cmTimeToSeek(index: index)
      player.seek(to: toSeek, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
      
      if index == 0 {
        generator.prepare()
        generator.notificationOccurred(.warning)
      }

//      if isMomentumSeeking {
//        let rate = self.momentumSeekRate(seekTo: toSeek)
//        print(rate)
//        if rate >= 0 && rate < 1.5 {
//          player.play()
////          scrollView.setContentOffset(scrollView.contentOffset, animated: false)
//          isMomentumSeeking = false
//          print("start")
//        }
//      }
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    player.play()
    isMomentumSeeking = false
  }
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    player.pause()
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if (!decelerate) {
      player.play()
      isMomentumSeeking = false
    } else {
      isMomentumSeeking = true
    }
  }
  
  func momentumSeekRate(seekTo: CMTime) -> Double {
    let currentTime = CACurrentMediaTime()
    let currentPosition = CMTimeGetSeconds(seekTo)
    let dPosition = currentPosition - lastSeekedPosition
    let dTime = currentTime - lastSeekedAt
    lastSeekedPosition = CMTimeGetSeconds(seekTo)
    lastSeekedAt = currentTime
    return dPosition / dTime
  }
}


// MARK: - For debugging

extension PlayerView {

  func nowTime() -> String {
    let format = DateFormatter()
    format.dateFormat = "HH:mm:ss.SSS"
    return format.string(from: Date())
  }
  
}
