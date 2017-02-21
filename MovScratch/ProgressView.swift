//
//  ProgressView.swift
//  MovScratch
//
//  Created by hor on 2017/02/21.
//  Copyright © 2017年 hor. All rights reserved.
//

import Foundation
import UIKit

class ProgressView: UIView {

  let gradientColors: [CGColor] = [UIColor(red:0.84, green:0.38, blue:0.98, alpha:1.0).cgColor,
                                   UIColor(red:0.20, green:0.60, blue:1.00, alpha:1.0).cgColor]

  let minHeight: CGFloat = 4.0
  
  var textureView: UIView!
  var containerView: UIView!
  
  var position: Double = 0 {
    didSet{
      let width = self.position * Double(self.bounds.width)
      containerView.frame.size.width = CGFloat(width)
    }
  }
  
  var expand: Bool = false {
    didSet{
      let expand = self.expand
      let height = expand ? self.bounds.height : minHeight

      if (expand) {
        containerView.frame.size.height = height
      }else{
        UIView.animate(withDuration: 0.2, animations: { [unowned self] _ in
          self.containerView.frame.size.height = height
          }, completion: { [unowned self] _ in
            self.containerView.frame.size.height = height
        })
      }
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    textureView = UIView(frame: self.bounds)
    print(self.bounds)
    let gradientLayer: CAGradientLayer = CAGradientLayer()
    gradientLayer.colors = gradientColors
    gradientLayer.frame = textureView.bounds
    gradientLayer.startPoint = CGPoint(x: 1.0, y: 0.5)
    gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.5)
    textureView.layer.insertSublayer(gradientLayer, at: 0)
    
    containerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: minHeight))
    containerView.addSubview(textureView)
    containerView.clipsToBounds = true
    self.addSubview(containerView)
    self.backgroundColor = UIColor.clear
  }
}
