//
//  TransitionSubmitButton.swift
//  Chat
//
//  Created by Eugene Korotky on 05.12.17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class TransitionSubmitButton: UIButton, UIViewControllerTransitioningDelegate, CAAnimationDelegate {
    lazy var spinner: SpinnerLayer = {
        let s = SpinnerLayer(frame: self.frame)
        self.layer.addSublayer(s)
        return s
    }()
    
    var spinnerColor: UIColor = .white {
        didSet {
            spinner.spinnerColor = self.spinnerColor
        }
    }
    
    var didEndFinishAnimation: (() -> ())? = nil
    
    let springGoEase = CAMediaTimingFunction(controlPoints: 0.45, -0.36, 0.44, 0.92)
    let shrinkCurve = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
    let expandCurve = CAMediaTimingFunction(controlPoints: 0.95, 0.02, 1, 0.05)
    let shrinkDuration: CFTimeInterval = 0.1
    
    var normalCornerRadius: CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = normalCornerRadius
        }
    }
    
    var cachedTitle: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        self.clipsToBounds = true
        self.spinner.spinnerColor = self.spinnerColor
    }
    
    func startLoadingAnimation() {
        self.cachedTitle = title(for: UIControlState())
        self.setTitle("", for: UIControlState())
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.layer.cornerRadius = strongSelf.frame.height / 2
        }) { [weak self] (done) in
            guard let strongSelf = self else { return }
            strongSelf.shrink()
            Timer.schedule(delay: strongSelf.shrinkDuration - 0.25, handler: { (timer) in
                strongSelf.spinner.animation()
            })
        }
    }
    
    func startFinishAnimation(_ delay: TimeInterval, completion: (() -> ())?) {
        Timer.schedule(delay: delay) { [weak self] (timer) in
            guard let strongSelf = self else { return }
            strongSelf.didEndFinishAnimation = completion
            strongSelf.expand()
            strongSelf.spinner.stopAnimation()
        }
    }
    
    func animate(_ duration: TimeInterval, completion: (() -> ())?) {
        self.startLoadingAnimation()
        self.startFinishAnimation(duration, completion: completion)
    }
    
    func setOriginalState() {
        self.returnToOriginalState()
        self.spinner.stopAnimation()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        let animation = anim as! CABasicAnimation
        if animation.keyPath == "transform.scale" {
            didEndFinishAnimation?()
            Timer.schedule(delay: 1, handler: { [weak self] (timer) in
                guard let strongSelf = self else { return }
                strongSelf.returnToOriginalState()
            })
        }
    }
    
    func returnToOriginalState() {
        self.layer.removeAllAnimations()
        self.setTitle(self.cachedTitle, for: UIControlState())
        self.spinner.stopAnimation()
        self.clipsToBounds = false
        self.layer.cornerRadius = 0.0
    }
    
    func shrink() {
        let shrinkAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        shrinkAnimation.fromValue = self.frame.width
        shrinkAnimation.toValue = self.frame.height
        shrinkAnimation.duration = self.shrinkDuration
        shrinkAnimation.timingFunction = self.shrinkCurve
        shrinkAnimation.fillMode = kCAFillModeForwards
        shrinkAnimation.isRemovedOnCompletion = false
        self.layer.add(shrinkAnimation, forKey: shrinkAnimation.keyPath)
    }
    
    func expand() {
        let expandAnimation = CABasicAnimation(keyPath: "transform.scale")
        expandAnimation.fromValue = 1.0
        expandAnimation.toValue = 26.0
        expandAnimation.timingFunction = self.expandCurve
        expandAnimation.duration = 0.3
        expandAnimation.delegate = self
        expandAnimation.fillMode = kCAFillModeForwards
        expandAnimation.isRemovedOnCompletion = false
        self.layer.add(expandAnimation, forKey: expandAnimation.keyPath)
    }
}
