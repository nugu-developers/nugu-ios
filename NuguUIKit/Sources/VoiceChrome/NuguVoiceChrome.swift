//
//  NuguVoiceChrome.swift
//  NuguUIKit
//
//  Created by jin kim on 23/08/2019.
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

import Lottie

import NuguUtils

/// <#Description#>
final public class NuguVoiceChrome: UIView {

    // MARK: - RecommendedHeight for NuguVoiceChrome
    // NuguVoiceChrome is designed in accordance with recommendedHeight
    // Note that NuguVoiceChrome can be looked awkward in different height
    
    /// <#Description#>
    public static let recommendedHeight: CGFloat = 68.0
    
    // MARK: - NuguVoiceChrome.NuguVoiceChromeTheme
    
    /// <#Description#>
    public enum NuguVoiceChromeTheme {
        case light
        case dark
        
        var backgroundColor: UIColor {
            switch self {
            case .light:
                return .white
            case .dark:
                return UIColor(red: 45.0/255.0, green: 51.0/255.0, blue: 57.0/255.0, alpha: 1.0)
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .light:
                return .black
            case .dark:
                return .white
            }
        }
    }
    
    // MARK: - Public Properties (configurable variables)
    
    /// <#Description#>
    public var theme: NuguVoiceChromeTheme = UserInterfaceUtil.style == .dark ? .dark : .light {
        didSet {
            backgroundView.backgroundColor = theme.backgroundColor
            coverView.backgroundColor = theme.backgroundColor
            guideTextLabel.textColor = theme.textColor
            recognizedTextLabel.textColor = theme.textColor
            animationContainerView.backgroundColor = theme.backgroundColor
            chipsView.theme = (theme == .light) ? .light : .dark
        }
    }
    
    public var onChipsSelect: ((_ selectedChips: NuguChipsButton.NuguChipsButtonType) -> Void)? {
        didSet {
            chipsView.onChipsSelect = onChipsSelect
        }
    }
    
    public private(set) var currentState: State = .listeningPassive
    
    // MARK: - Private Properties
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var coverView: UIView!
    @IBOutlet private weak var guideTextLabel: UILabel!
    @IBOutlet private weak var guideTextLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var recognizedTextLabel: UILabel!
    @IBOutlet private weak var animationContainerView: UIView!
    @IBOutlet private weak var chipsView: NuguChipsView!
    
    private var animationView = AnimationView()
    
    private let speechGuideText = "말씀해주세요"
    
    // MARK: - Override
    
    /// <#Description#>
    /// - Parameter frame: <#frame description#>
    public override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadFromXib()
    }
    
    private func loadFromXib() {
        // swiftlint:disable force_cast
        #if DEPLOY_OTHER_PACKAGE_MANAGER
        let view = Bundle(for: NuguVoiceChrome.self).loadNibNamed("NuguVoiceChrome", owner: self)?.first as! UIView
        #else
        let view = Bundle.module.loadNibNamed("NuguVoiceChrome", owner: self)?.first as! UIView
        #endif
        // swiftlint:enable force_cast
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: -1)
        layer.shadowRadius = 10
        
        animationView.frame = CGRect(x: 12, y: 0, width: 40, height: 40)
        animationContainerView.addSubview(animationView)
        
        theme = UserInterfaceUtil.style == .dark ? .dark : .light
        chipsView.willStartScrolling = { [weak self] in
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                self?.guideTextLabel.text = nil
                self?.guideTextLabelTrailingConstraint.constant = 0
                self?.layoutIfNeeded()
            })
        }
        
        changeState(state: .listeningPassive)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        setupBackgroundView()
    }
    
    private func setupBackgroundView() {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 12.0, height: 12.0)
        )
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        backgroundView.layer.mask = mask
    }
}

// MARK: - NuguVoiceChrome.State

public extension NuguVoiceChrome {
    /// <#Description#>
    enum State {
        case listeningPassive
        case listeningActive
        case processing
        case speaking
        case speakingError
        
        var transitionFileName: String {
            switch self {
            case .listeningPassive:
                return "01_intro"
            case .listeningActive:
                return "03_transition"
            case .processing:
                return "05_processing"
            case .speaking, .speakingError:
                return "06_transition"
            }
        }
        
        var animationFileName: String {
             switch self {
             case .listeningPassive:
                 return "02_passive"
             case .listeningActive:
                 return "04_active"
             case .processing:
                 return "05_processing"
             case .speaking, .speakingError:
                 return "07_speaking"
             }
         }
    }
}

// MARK: - Public

public extension NuguVoiceChrome {
    /// <#Description#>
    /// - Parameter state: <#state description#>
    func changeState(state: NuguVoiceChrome.State) {
        currentState = state
        playAnimationByState()
        switch state {
        case .listeningPassive:
            showSpeechGuideText()
        case .listeningActive, .speaking:
            setRecognizedText(text: nil)
        default: break
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - chipsData: <#chipsData description#>
    ///   - onChipsSelect: <#onChipsSelect description#>
    func setChipsData(_ chipsData: [NuguChipsButton.NuguChipsButtonType], onChipsSelect: @escaping ((_ selectedChips: NuguChipsButton.NuguChipsButtonType) -> Void)) {
        recognizedTextLabel.text = nil
        chipsView.chipsData = chipsData
        chipsView.isHidden = false
        chipsView.onChipsSelect = { [weak self] selectedChips in
            self?.animationView.stop()
            self?.setRecognizedText(text: nil)
            onChipsSelect(selectedChips)
        }
    }
    
    func setChipsData(_ chipsData: [NuguChipsButton.NuguChipsButtonType]) {
        recognizedTextLabel.text = nil
        chipsView.chipsData = chipsData
        chipsView.isHidden = false
        chipsView.onChipsSelect = { [weak self] selectedChips in
            self?.animationView.stop()
            self?.setRecognizedText(text: nil)
            self?.onChipsSelect?(selectedChips)
        }
    }
    
    /// <#Description#>
    /// - Parameter text: <#text description#>
    func setRecognizedText(text: String?) {
        recognizedTextLabel.text = text
        guideTextLabel.text = nil
        chipsView.isHidden = true
    }
}

// MARK: - Private

private extension NuguVoiceChrome {
    func playAnimationByState() {
        #if DEPLOY_OTHER_PACKAGE_MANAGER
        animationView.animation = Animation.named(currentState.transitionFileName, bundle: Bundle(for: NuguVoiceChrome.self))
        #else
        animationView.animation = Animation.named(currentState.transitionFileName, bundle: Bundle.module)
        #endif
        animationView.loopMode = .playOnce
        animationView.play { [weak self] (finished) in
            guard let self = self else { return }
            if finished {
                #if DEPLOY_OTHER_PACKAGE_MANAGER
                self.animationView.animation = Animation.named(self.currentState.animationFileName, bundle: Bundle(for: NuguVoiceChrome.self))
                #else
                self.animationView.animation = Animation.named(self.currentState.animationFileName, bundle: Bundle.module)
                #endif
                
                self.animationView.loopMode = .loop
                self.animationView.play()
            }
        }
    }
    
    func showSpeechGuideText() {
        recognizedTextLabel.text = nil
        guideTextLabel.text = speechGuideText
        guideTextLabelTrailingConstraint.constant = -14
    }
}
