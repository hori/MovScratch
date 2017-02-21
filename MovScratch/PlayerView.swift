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
  
  enum Direction: Int {
    case RightForward = -1
    case LeftForward  = 1
  }
  
  // Params
  let seekRate: Int = 4
  let decelerationRate: CGFloat = 0.8
  let swipeDirection: Direction = .RightForward

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
      self.syncScrollView(currentTime: self.player.currentTime())
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
  
  fileprivate func syncScrollView(currentTime: CMTime) {
    let index = self.frameIndexToSeek(cmTime: currentTime)
    let pos : Double = swipeDirection == .LeftForward ? Double(index*self.seekRate) : Double(self.scrollView.contentSize.width) -  Double(index*self.seekRate)
    scrollView.contentOffset.x = CGFloat(pos - Double(self.scrollView.contentInset.right))
//    print(pos)
  }

  fileprivate func videoFrameCount(asset: AVAsset) -> Int {
    guard let track = asset.tracks.first else { return 0 }
    let fps = track.nominalFrameRate
    let sec = Float(CMTimeGetSeconds(asset.duration))
    return Int (fps * sec)
  }

  fileprivate func cmTimeToSeek(index: Int) -> CMTime {
    let seekTo = (Double(index) / Double(scrollView.contentSize.width)) * CMTimeGetSeconds(asset.duration)
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
    if player.rate == 0 {
      let index:Int = swipeDirection == .LeftForward ? Int(scrollView.contentOffset.x + (scrollView.bounds.width/2)) : Int(scrollView.contentSize.width - scrollView.contentOffset.x + (scrollView.bounds.width/2))
      print(index)
      player.seek(to: self.cmTimeToSeek(index: index), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
      
      if index == 0 {
        generator.prepare()
        generator.notificationOccurred(.warning)
      }
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
}


// MARK: - For debugging

extension PlayerView {

  func nowTime() -> String {
    let format = DateFormatter()
    format.dateFormat = "HH:mm:ss.SSS"
    return format.string(from: Date())
  }
  
}
