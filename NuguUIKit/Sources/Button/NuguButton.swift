//
//  NuguButton.swift
//  NuguUIKit
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

/// <#Description#>
final public class NuguButton: UIButton {
    
    // MARK: - NuguButton.NuguButtonType
    
    /// <#Description#>
    public enum NuguButtonType {
        case fab(color: NuguButtonColor)
        case button(color: NuguButtonColor)
        
        /// <#Description#>
        public enum NuguButtonColor: String {
            case blue
            case white
        }
        
        var animationViewBackgroundColor: UIColor? {
            if case .button(let color) = self {
                switch color {
                case .blue:
                    return UIColor(red: 0.0/255.0, green: 107.0/255.0, blue: 173.0/255.0, alpha: 0.2)
                case .white:
                    return UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.2)
                }
            } else {
                return nil
            }
        }
        
        var animationViewBorderColor: CGColor? {
            if case .button(let color) = self {
                switch color {
                case .blue:
                    return UIColor(red: 0.0/255.0, green: 80.0/255.0, blue: 136.0/255.0, alpha: 0.2).cgColor
                case .white:
                    return UIColor(red: 173.0/255.0, green: 173.0/255.0, blue: 173.0/255.0, alpha: 0.2).cgColor
                }
            } else {
                return nil
            }
        }
            
        var animationViewHighlightedDotColor: UIColor? {
            if case .button(let color) = self {
                switch color {
                case .blue:
                    return UIColor(red: 22.0/255.0, green: 255.0/255.0, blue: 160.0/255.0, alpha: 1)
                case .white:
                    return UIColor(red: 0.0/255.0, green: 230.0/255.0, blue: 136.0/255.0, alpha: 1)
                }
            } else {
                return nil
            }
        }
        
        var animationViewDotColor: UIColor? {
            if case .button(let color) = self {
                switch color {
                case .blue:
                    return .white
                case .white:
                    return UIColor(red: 0.0/255.0, green: 157.0/255.0, blue: 255.0/255.0, alpha: 1)
                }
            } else {
                return nil
            }
        }
    }
    
    // MARK: - Public Properties (configurable variables)
    
    /// <#Description#>
    public var nuguButtonType: NuguButtonType = .fab(color: .blue) {
        didSet {
            addImageViews()
            setButtonImages()
        }
    }
    
    /// <#Description#>
    public var isActivated: Bool = true {
        didSet {
            updateActivationState()
        }
    }
    
    // MARK: - Private Properties
    
    private var deactivateAnimationView: UIView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 44.0, height: 44.0)))
    
    private var highlightedDotIndex = 0
    
    private var animationTimer: DispatchSourceTimer?
    
    private var micFlipAnimationTimer: DispatchSourceTimer?
    
    private let micFlipAnimationTimerQueue = DispatchQueue(label: "MicFlipAnimation")
    
    private var micImageView = UIImageView(frame: .zero)
    
    private var backgroundImageView = UIImageView(frame: .zero)
    
    private var flipped: Bool = false {
        didSet {
            updateButtonImages()
        }
    }
    
    // MARK: - Override
    
    public override var isHighlighted: Bool {
        didSet {
            updateButtonImages()
        }
    }
    
    /// <#Description#>
    public override var isEnabled: Bool {
        didSet {
            if self.isEnabled {
                switch nuguButtonType {
                case .fab(let color):
                    micImageView.image = UIImage(named: "fab_\(color.rawValue)_mic", in: Bundle.imageBundle, compatibleWith: nil)
                    backgroundImageView.image = UIImage(named: "fab_\(color.rawValue)_background", in: Bundle.imageBundle, compatibleWith: nil)
                case .button(let color):
                    micImageView.image = UIImage(named: "btn_\(color.rawValue)_mic", in: Bundle.imageBundle, compatibleWith: nil)
                    backgroundImageView.image = UIImage(named: "btn_\(color.rawValue)_background", in: Bundle.imageBundle, compatibleWith: nil)
                }
            } else {
                switch nuguButtonType {
                case .fab:
                    micImageView.image = UIImage(named: "fab_mic_disabled", in: Bundle.imageBundle, compatibleWith: nil)
                    backgroundImageView.image = UIImage(named: "fab_background_disabled", in: Bundle.imageBundle, compatibleWith: nil)
                case .button:
                    micImageView.image = UIImage(named: "btn_disabled", in: Bundle.imageBundle, compatibleWith: nil)
                    backgroundImageView.image = UIImage(named: "btn_background_disabled", in: Bundle.imageBundle, compatibleWith: nil)
                }
            }
        }
    }
    
    /// <#Description#>
    /// - Parameter frame: <#frame description#>
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addImageViews()
        setButtonImages()
        updateActivationState()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addImageViews()
        setButtonImages()
        updateActivationState()
    }
    
    // MARK: - Public Methods (Flip Animation)
    
    /// <#Description#>
    public func startFlipAnimation() {
        guard micImageView.layer.animationKeys() == nil else {
            return
        }
        flipped = false
        micFlipAnimationTimer?.cancel()
        micFlipAnimationTimer = DispatchSource.makeTimerSource(queue: micFlipAnimationTimerQueue)
        micFlipAnimationTimer?.schedule(deadline: .now(), repeating: 3.0)
        micFlipAnimationTimer?.setEventHandler(handler: {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.flipMic()
            }
        })
        micFlipAnimationTimer?.resume()
    }
    
    /// <#Description#>
    public func stopFlipAnimation() {
        flipped = false
        micImageView.layer.transform = CATransform3DIdentity
        micImageView.layer.removeAllAnimations()
        micFlipAnimationTimer?.cancel()
        micFlipAnimationTimer = nil
    }
    
    /// <#Description#>
    public func pauseDeactivateAnimation() {
        animationTimer?.cancel()
    }
}

// MARK: - Private

private extension NuguButton {
    func updateButtonImages() {
        guard isEnabled == true else { return }
        
        let imgNamePrefix: String
        let imgNameColor: String
        switch nuguButtonType {
        case .fab(let color):
            imgNamePrefix = "fab"
            imgNameColor = color.rawValue
        case .button(let color):
            imgNamePrefix = "btn"
            imgNameColor = color.rawValue
        }
        
        let imgNamePostfix = flipped ? "logo" : "mic"
        let imgNameState = isHighlighted ? "_pressed" : ""
        
        micImageView.image = UIImage(
            named: "\(imgNamePrefix)_\(imgNameColor)_\(imgNamePostfix)" + imgNameState,
            in: Bundle.imageBundle,
            compatibleWith: nil
        )
        
        backgroundImageView.image = UIImage(
            named: "\(imgNamePrefix)_\(imgNameColor)_background" + imgNameState,
            in: Bundle.imageBundle,
            compatibleWith: nil
        )
    }
    
    func addImageViews() {
        switch nuguButtonType {
        case .fab:
            micImageView.frame = bounds.inset(by: UIEdgeInsets(top: 13.0, left: 17.0, bottom: 21.0, right: 17.0))
        case .button:
            micImageView.frame = bounds.inset(by: UIEdgeInsets(top: 13.0, left: 13.0, bottom: 13.0, right: 13.0))
        }
        backgroundImageView.frame = bounds
        backgroundImageView.addSubview(micImageView)
        addSubview(backgroundImageView)
    }
    
    func setButtonImages() {
        switch nuguButtonType {
        case .fab(let color):
            micImageView.image = UIImage(named: "fab_\(color.rawValue)_mic", in: Bundle.imageBundle, compatibleWith: nil)
            backgroundImageView.image = UIImage(named: "fab_\(color.rawValue)_background", in: Bundle.imageBundle, compatibleWith: nil)
        case .button(let color):
            micImageView.image = UIImage(named: "btn_\(color.rawValue)_mic", in: Bundle.imageBundle, compatibleWith: nil)
            backgroundImageView.image = UIImage(named: "btn_\(color.rawValue)_background", in: Bundle.imageBundle, compatibleWith: nil)
        }
    }
    
    func updateActivationState() {
        switch nuguButtonType {
        case .fab:
            alpha = isActivated ? 1.0 : 0.0
        case .button:
            isActivated ? stopDeactivateAnimation() : startDeactivateAnimation()
        }
    }
    
    func startDeactivateAnimation() {
        deactivateAnimationView.center = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        deactivateAnimationView.layer.cornerRadius = 22.0
        deactivateAnimationView.clipsToBounds = true
        deactivateAnimationView.backgroundColor = nuguButtonType.animationViewBackgroundColor
        deactivateAnimationView.layer.borderColor = nuguButtonType.animationViewBorderColor
        deactivateAnimationView.layer.borderWidth = 1.0
        
        for index in 0...2 {
            let dotView = UIView(frame: CGRect(x: 8.0 + 12.0 * Double(index), y: 20.0, width: 4.0, height: 4.0))
            dotView.layer.cornerRadius = 2.0
            dotView.clipsToBounds = true
            dotView.tag = index
            deactivateAnimationView.addSubview(dotView)
        }
        
        animationTimer = DispatchSource.makeTimerSource(queue: .main)
        animationTimer?.schedule(deadline: .now(), repeating: 0.66)
        animationTimer?.setEventHandler(handler: { [weak self] in
            guard let self = self else { return }
            for dotView in self.deactivateAnimationView.subviews {
                dotView.backgroundColor = self.highlightedDotIndex == dotView.tag ? self.nuguButtonType.animationViewHighlightedDotColor : self.nuguButtonType.animationViewDotColor
            }
            self.highlightedDotIndex = self.highlightedDotIndex == 2 ? 0 : self.highlightedDotIndex + 1
        })
        animationTimer?.resume()
        
        addSubview(deactivateAnimationView)
        backgroundImageView.isHidden = true
        isUserInteractionEnabled = false
    }
    
    func stopDeactivateAnimation() {
        imageView?.isHidden = false
        highlightedDotIndex = 0
        animationTimer?.cancel()
        deactivateAnimationView.removeFromSuperview()
        backgroundImageView.isHidden = false
        isUserInteractionEnabled = true
    }
    
    func flipMic() {
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseOut], animations: { [weak self] in
            self?.micImageView.layer.transform = CATransform3DRotate(CATransform3DIdentity, CGFloat(Double.pi/2), 0.0, 1.0, 0.0)
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                self.flipped = !self.flipped
                UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseOut], animations: { [weak self] in
                    self?.micImageView.layer.transform = CATransform3DRotate(CATransform3DIdentity, CGFloat(2*Double.pi), 0.0, 1.0, 0.0)
                    }, completion: { [weak self] _ in
                        self?.micImageView.layer.transform = CATransform3DIdentity
                })
        })
    }
}
