//
//  SpinnerLayer.swift
//  Chat
//
//  Created by Eugene Korotky on 05.12.17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class SpinnerLayer: CAShapeLayer {
    var spinnerColor: UIColor = .white {
        didSet {
            strokeColor = spinnerColor.cgColor
        }
    }
    
    init(frame: CGRect) {
        super.init()
        
        let radius: CGFloat = frame.height / 4
        self.frame = CGRect(x: 0, y: 0, width: frame.height, height: frame.height)
        
        let center = CGPoint(x: frame.height / 2, y: bounds.center.y)
        let startAngle: CGFloat = 0 - CGFloat.pi / 2
        let endAngle: CGFloat = CGFloat.pi * 2 - CGFloat.pi / 2
        let clockWise = true
        self.path = UIBezierPath(arcCenter: center,
                                 radius: radius,
                                 startAngle: startAngle,
                                 endAngle: endAngle,
                                 clockwise: clockWise).cgPath
        
        self.fillColor = nil
        self.strokeColor = self.spinnerColor.cgColor
        self.lineWidth = 1.0
        self.strokeEnd = 0.4
        self.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func animation() {
        self.isHidden = false
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fromValue = 0.0
        rotate.toValue = Double.pi * 2
        rotate.duration = 0.4
        rotate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        rotate.repeatCount = HUGE
        rotate.fillMode = kCAFillModeForwards
        rotate.isRemovedOnCompletion = false
        self.add(rotate, forKey: rotate.keyPath)
    }
    
    func stopAnimation() {
        self.isHidden = true
        self.removeAllAnimations()
    }
}
