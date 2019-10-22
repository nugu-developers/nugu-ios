//
//  NuguButton.swift
//  SampleApp-iOS
//
//  Created by jin kim on 03/07/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

final class NuguButton: UIButton {
    
    // MARK: AnimationKey
    
    enum AnimationKey: String {
        case gradation = "gradation"
        case flip = "flip"
    }
    
    // MARK: Properties
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var imagesStackView: UIStackView!
    @IBOutlet private weak var micImageView: UIImageView!
    @IBOutlet private weak var nuguLogoImageView: UIImageView!
    
    @IBInspectable
    private var startColor: UIColor = UIColor(rgbHexValue: 0x009DFF)
    
    @IBInspectable
    private var endColor: UIColor = UIColor(rgbHexValue: 0x009DFF)
    
    @IBInspectable
    private var showNuguLogo: Bool = true {
        didSet {
            nuguLogoImageView.isHidden = !showNuguLogo
        }
    }
    
    private var gradientLayer = CAGradientLayer()
    private var highlightedLayer = CALayer()
    
    // MARK: Override
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadFromXib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        refreshViews()
    }
    
    override var isHighlighted: Bool {
        didSet {
            highlightedLayer.isHidden = !isHighlighted
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled == true {
                startColor = UIColor(rgbHexValue: 0x009DFF)
                endColor = UIColor(rgbHexValue: 0x009DFF)
            } else {
                startColor = UIColor(rgbHexValue: 0x78838F)
                endColor = UIColor(rgbHexValue: 0x78838F)
            }
            refreshViews()
        }
    }

}

// MARK: - Internal (Animation)

extension NuguButton {
    func startListeningAnimation() {
        animateFlip()
        animateGradation()
    }
    
    func stopListeningAnimation() {
        micImageView.layer.removeAllAnimations()
        gradientLayer.removeAllAnimations()
    }
}

// MARK: - Private (View)

extension NuguButton {
    private func loadFromXib() {
        let view = Bundle.main.loadNibNamed("NuguButton", owner: self)?.first as! UIView
        view.frame = bounds
        addSubview(view)
        
        // CHECK-ME:
        // let ratio = bounds.size.width / view.bounds.size.width
        // imagesStackView.spacing *= ratio
        
        highlightedLayer.isHidden = true
        gradientLayer.isHidden = false
        nuguLogoImageView.isHidden = !showNuguLogo
        
        gradientLayer.shadowColor = UIColor.black.cgColor
        gradientLayer.shadowOpacity = 0.2
        gradientLayer.shadowOffset = CGSize(width: 0, height: 4)
        gradientLayer.shadowRadius = 8
        
        highlightedLayer.backgroundColor = UIColor.black.cgColor
        highlightedLayer.opacity = 0.16
        
        backgroundView.layer.addSublayer(gradientLayer)
        backgroundView.layer.addSublayer(highlightedLayer)
    }
    
    func refreshViews() {
        containerView.layer.cornerRadius = containerView.frame.height / 2.0
        
        // Add gradientlayer
        gradientLayer.frame = containerView.bounds
        gradientLayer.cornerRadius = containerView.layer.cornerRadius
        
        gradientLayer.startPoint = CGPoint(x:0.5, y:0.0)
        gradientLayer.endPoint = CGPoint(x:0.5, y:1.0)
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.locations =  [0, 1.0]
        
        // Add highlightedLayer
        highlightedLayer.frame = containerView.bounds
        highlightedLayer.cornerRadius = containerView.layer.cornerRadius
    }
    
    func animateFlip() {
        switch micImageView.layer.animationKeys() {
        case .some(let keys) where keys.contains(AnimationKey.flip.rawValue):
            // Already has animation
            return
        default:
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation.y")
            animation.duration = 5.0
            animation.values = [0, 1.0 * Double.pi]
            animation.keyTimes = [0, 0.2]
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            micImageView.layer.add(animation, forKey: AnimationKey.flip.rawValue)
        }
    }
    
    func animateGradation() {
        switch gradientLayer.animationKeys() {
        case .some(let keys) where keys.contains(AnimationKey.gradation.rawValue):
            // Already has animation
            return
        default:
            let animation = CABasicAnimation(keyPath: "colors")
            animation.fromValue = [startColor.cgColor, endColor.cgColor]
            animation.toValue = [endColor.cgColor, startColor.cgColor]
            animation.duration = 1.0
            animation.autoreverses = true
            animation.repeatCount = .infinity
                
            gradientLayer.add(animation, forKey: AnimationKey.gradation.rawValue)
        }
    }
}
