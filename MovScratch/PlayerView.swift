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

protocol PlayerViewDelegate {

  func playerViewWillBeginSeeking() -> Void
  func playerViewDidEndSeeking() -> Void
  func playerViewDidChangePosition(_ currentPosition: Double) -> Void

}

class PlayerView: UIView {
  
  var delegate: PlayerViewDelegate?
  
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
    scrollView.contentInset = UIEdgeInsets(top: 0, left: scrollView.frame.size.width / 2, bottom: 0, right: scrollView.frame.size.width / 2)
    scrollView.delegate = self
    scrollView.bounces = false
    scrollView.decelerationRate = decelerationRate

    print("contentInset.left  :", scrollView.contentInset.left)
    print("contentInset.right :", scrollView.contentInset.right)
    
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
    let pos : Double = swipeDirection == .LeftForward
                      ? Double(index*self.seekRate) - Double(self.scrollView.contentInset.left)
                      : Double(self.scrollView.contentSize.width) - (Double(index*self.seekRate) + Double(self.scrollView.contentInset.right))
    scrollView.contentOffset.x = CGFloat(pos)
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

    self.delegate?.playerViewDidChangePosition( CMTimeGetSeconds(player.currentTime()) / CMTimeGetSeconds(asset.duration))

    if player.rate == 0 {
      let index:Int = swipeDirection == .LeftForward
                      ? Int(scrollView.contentOffset.x - scrollView.contentInset.left)
                      : Int(scrollView.contentSize.width - (scrollView.contentOffset.x + scrollView.contentInset.left))
      player.seek(to: self.cmTimeToSeek(index: index), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)

      if index == 0 {
        generator.prepare()
        generator.notificationOccurred(.warning)
      }
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    player.play()
    self.delegate?.playerViewDidEndSeeking()
  }
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    player.pause()
    self.delegate?.playerViewWillBeginSeeking()
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if (!decelerate) {
      player.play()
      self.delegate?.playerViewDidEndSeeking()
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
