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

  var player: AVPlayer!
  var videoFrameCount: Int!
  var scrollView: UIScrollView!

  var asset: AVAsset! {
    didSet {
      guard let asset = self.asset else { return }
      player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
      playerLayer.player = player
      videoFrameCount = self.videoFrameCount(asset: asset)
      self.setupScrollView(width: videoFrameCount)
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
  
  // MARK: - setup
  fileprivate func setupScrollView(width: Int) {
    scrollView.contentSize = CGSize(width: CGFloat(width), height: scrollView.bounds.size.height)
    scrollView.contentInset.left = scrollView.bounds.size.width/2
    scrollView.contentInset.right = scrollView.bounds.size.width/2
    scrollView.delegate = self
    scrollView.bounces = false
    
    // sync scrollview
    let time : CMTime = CMTimeMakeWithSeconds(0.1, Int32(NSEC_PER_SEC))
    player.addPeriodicTimeObserver(forInterval: time, queue: nil) { [unowned self] (time) -> Void in
      guard self.player.rate != 0 else {return}
      let index = self.frameIndexToSeek(cmTime: self.player.currentTime())
      self.scrollView.contentOffset.x = CGFloat(Double(index) - Double(self.scrollView.contentInset.right))
    }
  }
  // MARK: - To seek

  fileprivate func videoFrameCount(asset: AVAsset) -> Int {
    guard let track = asset.tracks.first else { return 0 }
    let fps = track.nominalFrameRate
    let sec = Float(CMTimeGetSeconds(asset.duration))
    return Int (fps * sec)
  }

  fileprivate func cmTimeToSeek(index: Int) -> CMTime {
    let seekTo = (Double(index) / Double(videoFrameCount - 1)) * CMTimeGetSeconds(asset.duration)
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

//MARK: - UIScrollViewDelegate
extension PlayerView: UIScrollViewDelegate {
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let index = Int(scrollView.contentOffset.x + (scrollView.bounds.width/2))
    if player.rate == 0 {
      player.seek(to: self.cmTimeToSeek(index: index), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    print("scrollViewDidEndDecelerating")
    player.play()
  }
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    print("scrollViewWillBeginDragging")
    player.pause()
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    print("scrollViewDidEndDragging")
    if (!decelerate) {
      player.play()
    }
  }

}
