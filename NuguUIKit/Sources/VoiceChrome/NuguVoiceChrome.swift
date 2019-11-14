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
    
    // MARK: RecommendedHeight for NuguVoiceChrome
    // NuguVoiceChrome is designed in accordance with recommendedHeight
    // Note that NuguVoiceChrome can be looked awkward in different height
    
    public static let recommendedHeight: CGFloat = 256.0
    
    // MARK: Customizable Properties
    
    public var onCloseButtonClick: (() -> Void)?
    
    // MARK: Private Properties
    
    @IBOutlet private weak var backgroundView: UIView!
    
    @IBOutlet private weak var stackView: UIStackView!
    
    @IBOutlet private weak var topContainerView: UIView!
    @IBOutlet private weak var recognizedTextLabel: UILabel!
    
    @IBOutlet private weak var animationView: NuguVoiceChromeAnimationView!
    
    private let speechGuideText = "말씀해주세요"
    private let guideTextColor = UIColor(red: 112.0/255.0, green: 118.0/255.0, blue: 125.0/255.0, alpha: 1.0)
    private let recognizeTextColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0)
    
    // MARK: Override
    
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
    }
}

// MARK: - Public

public extension NuguVoiceChrome {
    func changeState(state: NuguVoiceChrome.State) {
        animationView.setAnimation(state: state)
        switch state {
        case .listeningPassive:
            showSpeechGuideText()
        case .listeningActive:
            setRecognizedText(text: nil)
        default: break
        }
    }
    
    func setRecognizedText(text: String?) {
        recognizedTextLabel.textColor = recognizeTextColor
        recognizedTextLabel.text = text
    }
    
    func minimize() {
        guard topContainerView.isHidden == false else { return }
        topContainerView.alpha = 0
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.topContainerView.isHidden = true
            self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y + self.topContainerView.frame.size.height, width: self.frame.size.width, height: self.frame.size.height - self.topContainerView.frame.size.height)
            self.stackView.layoutIfNeeded()
        }
    }
    
    func maximize() {
        guard topContainerView.isHidden == true else { return }
        
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                guard let self = self else { return }
                self.topContainerView.isHidden = false
                self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y - self.topContainerView.frame.size.height, width: self.frame.size.width, height: self.frame.size.height + self.topContainerView.frame.size.height)
                self.stackView.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                self?.topContainerView.alpha = 1
        })
    }
}

// MARK: - Private

private extension NuguVoiceChrome {
    func showSpeechGuideText() {
        recognizedTextLabel.text = speechGuideText
        recognizedTextLabel.textColor = guideTextColor
    }
}

// MARK: - IBActions

private extension NuguVoiceChrome {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
}
