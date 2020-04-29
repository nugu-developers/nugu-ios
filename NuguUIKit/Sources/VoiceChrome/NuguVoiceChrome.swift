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

final public class NuguVoiceChrome: UIView {

    // MARK: - RecommendedHeight for NuguVoiceChrome
    // NuguVoiceChrome is designed in accordance with recommendedHeight
    // Note that NuguVoiceChrome can be looked awkward in different height
    
    public static let recommendedHeight: CGFloat = 68.0
    
    // MARK: - NuguVoiceChrome.NuguVoiceChromeTheme
    
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
    
    public var theme: NuguVoiceChromeTheme = .light {
        didSet {
            backgroundView.backgroundColor = theme.backgroundColor
            guideTextLabel.textColor = theme.textColor
            recognizedTextLabel.textColor = theme.textColor
            animationContainerView.backgroundColor = theme.backgroundColor
            chipsView.theme = (theme == .light) ? .light : .dark
        }
    }
    
    // MARK: - Private Properties
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var guideTextLabel: UILabel!
    @IBOutlet private weak var recognizedTextLabel: UILabel!
    @IBOutlet private weak var animationContainerView: UIView!
    @IBOutlet private weak var chipsView: NuguChipsView!
    
    private var animationView = AnimationView()
    
    private let speechGuideText = "말씀해주세요"
    
    // MARK: - Override
    
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
        let view = Bundle(for: NuguVoiceChrome.self).loadNibNamed("NuguVoiceChrome", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        backgroundView.layer.cornerRadius = 12.0
        backgroundView.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        backgroundView.layer.borderWidth = 0.5
        backgroundView.clipsToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: -1)
        layer.shadowRadius = 10
        
        animationView.frame = CGRect(x: 12, y: 0, width: 40, height: 40)
        animationContainerView.addSubview(animationView)
        
        theme = .light
        chipsView.willStartScrolling = {
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                self?.guideTextLabel.text = nil
                self?.layoutIfNeeded()
            })
        }
    }
}

// MARK: - NuguVoiceChrome.State

public extension NuguVoiceChrome {
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
    func changeState(state: NuguVoiceChrome.State) {
        playAnimationByState(state: state)
        switch state {
        case .listeningPassive:
            showSpeechGuideText()
        case .listeningActive:
            setRecognizedText(text: nil)
        default: break
        }
    }
    
    func setChipsData(chipsData: [NuguChipsButton.NuguChipsButtonType], onChipsSelect: @escaping (_ text: String?) -> Void) {
        chipsView.chipsData = chipsData
        chipsView.isHidden = false
        chipsView.onChipsSelect = { [weak self] text in
            self?.setRecognizedText(text: text)
            onChipsSelect(text)
        }
    }
    
    func setRecognizedText(text: String?) {
        recognizedTextLabel.text = text
        guideTextLabel.text = nil
        chipsView.isHidden = true
    }
}

// MARK: - Private

private extension NuguVoiceChrome {
    func playAnimationByState(state: NuguVoiceChrome.State) {
        animationView.animation = Animation.named(state.transitionFileName, bundle: Bundle(for: NuguVoiceChrome.self))
        animationView.loopMode = .playOnce
        animationView.play { [weak self] (finished) in
            if finished {
                self?.animationView.animation = Animation.named(state.animationFileName, bundle: Bundle(for: NuguVoiceChrome.self))
                self?.animationView.loopMode = .loop
                self?.animationView.play()
            }
        }
    }
    
    func showSpeechGuideText() {
        recognizedTextLabel.text = nil
        guideTextLabel.text = speechGuideText
    }
}
