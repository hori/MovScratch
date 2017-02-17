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

  var playerItem: AVPlayerItem!
  var player: AVPlayer!
  var scrollImageView: UIImageView!

  var seekTo: CMTime?

  var frames: [CIImage] = []
  var needImpactFeedback:Bool = false
  
  var assetSize: CGSize?

  @IBOutlet weak var playerView: PlayerView!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var scrollView: UIScrollView!

  func asset() -> AVAsset {
    let path = Bundle.main.path(forResource: "snowboarding_480p", ofType: "m4v")
    let asset = AVURLAsset(url: URL(fileURLWithPath: path!))
    return asset
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let asset = self.asset()
    assetSize = asset.tracks(withMediaType: AVMediaTypeVideo)[0].naturalSize
    

    playerItem = AVPlayerItem(asset: asset)
    player = AVPlayer(playerItem: playerItem)
    playerView.player = player
    
    player.play()
    imageView.isHidden = true
    
    // setup guesture
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panView(sender:)))
    playerView.addGestureRecognizer(panGesture)

    self.buffering()

    self.setupScrollView()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func setupScrollView() {
    let width = frames.count
    scrollImageView = UIImageView(image: UIImage(named: "scroll_texture"))
    scrollImageView.contentMode = .scaleToFill
    scrollImageView.bounds.size = CGSize(width: CGFloat(width), height: scrollView.bounds.size.height)
    scrollView.addSubview(scrollImageView)
    scrollView.contentSize = scrollImageView.bounds.size
    scrollView.contentInset.left = scrollView.bounds.size.width/2
    scrollView.contentInset.right = scrollView.bounds.size.width/2
    scrollView.delegate = self
    scrollView.bounces = false

    // sync scrollview
    let time : CMTime = CMTimeMakeWithSeconds(0.1, Int32(NSEC_PER_SEC))
    player.addPeriodicTimeObserver(forInterval: time, queue: nil) { [unowned self] (time) -> Void in
      guard self.player.rate != 0 else {return}
      let index = self.indexToSeek(cmTime: self.player.currentTime())
      self.scrollView.contentOffset.x = CGFloat(Double(index) - Double(self.scrollView.contentInset.right))
    }
  }
  
  
  func panView(sender: AnyObject) {
    if (sender.state == UIGestureRecognizerState.began) {
      player.pause()
    }

    let currentTime = CMTimeGetSeconds(player.currentTime())
    let totalTime = CMTimeGetSeconds(self.asset().duration)
    let location: CGPoint = sender.translation(in: playerView)
    
    var currentIndex:Int = Int( (currentTime/totalTime) * Double(frames.count)) + Int(location.x)
    if currentIndex < 0 {
      currentIndex = 0
      needImpactFeedback = true
    } else if ( currentIndex >= frames.count - 1 ) {
      currentIndex = frames.count - 1
      needImpactFeedback = true
    }
    imageView.image = self.uiImage(index: currentIndex)
    
    if (needImpactFeedback) {
      let generator = UIImpactFeedbackGenerator(style: .medium)
      generator.prepare()
      needImpactFeedback = false
    }

    if (sender.state == UIGestureRecognizerState.began) {
      imageView.isHidden = false
      playerView.isHidden = true
    }

    if (sender.state == UIGestureRecognizerState.ended) {
      let velocity: CGPoint = sender.velocity(in: playerView)
      let images = self.uiImagesForAnimation(currentIndex: currentIndex, velocity: Float(velocity.x))

      if images.count > 0 {
        let duration = Double(images.count) / 30.0
        imageView.animationImages = images
        imageView.animationDuration = duration
        imageView.animationRepeatCount = 1
        imageView.startAnimating()
        player.seek(to: seekTo!, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        seekTo = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [unowned self] _ in
          self.player.play()
          self.playerView.isHidden = false
          self.imageView.isHidden = true
        }
        

      } else {
        seekTo = cmTimeToSeek(index: currentIndex)
        player.seek(to: seekTo!, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        player.play()
        seekTo = nil
        playerView.isHidden = false
        imageView.isHidden = true
      }

    }
    
    
  }

  
  func buffering() {
    print(self.nowTime())

    let asset = self.asset()
    let reader = try! AVAssetReader(asset: asset)
    
    let videoTrack = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
    let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
    reader.add(trackReaderOutput)
    reader.startReading()
    
    while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
      if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {

//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        frames.append(ciImage)
        
//        let uiImage = UIImage(ciImage: ciImage)

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        frames.append(ciImage)
//        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
//        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
//        let imageRect:CGRect = CGRect(x: 0, y: 0, width: pixelBufferWidth, height: pixelBufferHeight)
//        let ciContext = CIContext.init()
//        let cgImage = ciContext.createCGImage(ciImage, from: imageRect )
//        let uiImage = self.resize(uiImage: UIImage(cgImage: cgImage!, scale: 1, orientation: UIImageOrientation.right), scale: 1/2)
//        frames.append(uiImage!)
      }
    }
    print(self.nowTime())
    print(frames.count)
  }
  
  func resize(uiImage: UIImage, scale: Float) -> UIImage? {
    let size = CGSize(width: uiImage.size.width * CGFloat(scale), height: uiImage.size.height * CGFloat(scale))
    UIGraphicsBeginImageContext(size)
    uiImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return resizedImage
  }
  
  func uiImagesForAnimation(currentIndex: Int, velocity: Float) -> [UIImage]{
    guard frames.count > 0 else { return []}
    var images:[UIImage] = []
    var indexise:[Int] = []
    let friction:Float = 0.95
    var v:Int = Int(velocity / 150)
    var i:Int = currentIndex

    while true {
      i = i + v
      v = Int(Float(v) * friction)
      if (i < 0 || i > frames.count - 1) { break }
      if (v == 0) { break }
      images.append(self.uiImage(index: i))
      indexise.append(i)
    }
    print(indexise)
    seekTo = self.cmTimeToSeek(index: i)
    print(CMTimeGetSeconds(seekTo!))
    return images
  }
  
//MARK: - for debugging

  func nowTime() -> String {
    let format = DateFormatter()
    format.dateFormat = "HH:mm:ss.SSS"
    return format.string(from: Date())
  }
  
  func cmTimeToSeek(index: Int) -> CMTime {
    let seekTo = (Double(index) / Double(frames.count-1)) * CMTimeGetSeconds(asset().duration)
    if seekTo < 0 {return kCMTimeZero}
    if seekTo > CMTimeGetSeconds(asset().duration) {return asset().duration}
    return CMTimeMakeWithSeconds(seekTo, Int32(NSEC_PER_SEC))
  }

  func indexToSeek(cmTime: CMTime) -> Int {
    let seekTo = Int((CMTimeGetSeconds(cmTime) / CMTimeGetSeconds(asset().duration)) * Double(frames.count))
    if seekTo < 0 {return 0}
    if seekTo > (frames.count - 1)  {return (frames.count - 1)}
    return seekTo
  }

  func uiImage(index: Int) -> UIImage {
    guard let size = assetSize else { return UIImage() }
    let ciImage = frames[index]
    let imageRect:CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    let ciContext = CIContext.init()
    let cgImage = ciContext.createCGImage(ciImage, from: imageRect )
    let uiImage = UIImage(cgImage: cgImage!, scale: 1, orientation: UIImageOrientation.right)
    return uiImage

  }
}

//MARK: - UIScrollViewDelegate
extension ViewController: UIScrollViewDelegate {

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    print(scrollView.contentOffset.x + (scrollView.bounds.width/2))
    let index = Int(scrollView.contentOffset.x + (scrollView.bounds.width/2))
    if player.rate == 0 {
      player.seek(to: self.cmTimeToSeek(index: index), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    print(scrollView.contentOffset.x + (scrollView.bounds.width/2))
    print("scrollViewDidEndDecelerating")
    player.play()
  }
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    print("scrollViewWillBeginDragging")
    player.pause()
  }
}

