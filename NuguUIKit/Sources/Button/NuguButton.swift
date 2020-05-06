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

final public class NuguButton: UIButton {
    
    // MARK: - NuguButton.NuguButtonType
    
    public enum NuguButtonType {
        case fab(color: NuguButtonColor)
        case button(color: NuguButtonColor)
        
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
    
    public var nuguButtonType: NuguButtonType = .fab(color: .blue) {
        didSet {
            setButtonImages()
        }
    }
    
    public var isActivated: Bool = true {
        didSet {
            updateActivationState()
        }
    }
    
    private var deactivateAnimationView: UIView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 44.0, height: 44.0)))
    
    private var highlightedDotIndex = 0
    
    private var animationTimer: DispatchSourceTimer?
    
    // MARK: - Override
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setButtonImages()
        updateActivationState()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setButtonImages()
        updateActivationState()
    }
}

// MARK: - Private

private extension NuguButton {
    func setButtonImages() {
        switch nuguButtonType {
        case .fab(let color):
            setImage(UIImage(named: "fab_\(color.rawValue)", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .normal)
            setImage(UIImage(named: "fab_\(color.rawValue)_pressed", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .highlighted)
            setImage(UIImage(named: "fab_disabled", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .disabled)
        case .button(let color):
            setImage(UIImage(named: "btn_\(color.rawValue)", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .normal)
            setImage(UIImage(named: "btn_\(color.rawValue)_pressed", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .highlighted)
            setImage(UIImage(named: "btn_disabled", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .disabled)
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
        animationTimer?.schedule(deadline: .now(), repeating: 1.0)
        animationTimer?.setEventHandler(handler: { [weak self] in
            guard let self = self else { return }
            for dotView in self.deactivateAnimationView.subviews {
                dotView.backgroundColor = self.highlightedDotIndex == dotView.tag ? self.nuguButtonType.animationViewHighlightedDotColor : self.nuguButtonType.animationViewDotColor
            }
            self.highlightedDotIndex = self.highlightedDotIndex == 2 ? 0 : self.highlightedDotIndex + 1
        })
        animationTimer?.resume()
        
        addSubview(deactivateAnimationView)
        setImage(nil, for: .normal)
        isUserInteractionEnabled = false
    }
    
    func stopDeactivateAnimation() {
        imageView?.isHidden = false
        highlightedDotIndex = 0
        animationTimer?.cancel()
        deactivateAnimationView.removeFromSuperview()
        setButtonImages()
        isUserInteractionEnabled = true
    }
}
