//
//  VoiceChromeView.swift
//  SampleApp-iOS
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

import NuguInterface

import Lottie

final class VoiceChromeView: UIView {
    @IBOutlet private weak var backgroundView: UIView!
    
    @IBOutlet private weak var stackView: UIStackView!
    
    @IBOutlet private weak var topContainerView: UIView!
    @IBOutlet private weak var recognizedTextLabel: UILabel!
    
    @IBOutlet private weak var asrStatusView: AnimationView!
    
    var onCloseButtonClick: (() -> Void)?
    
    private let speechGuideText = "말씀해주세요"
    private let guideTextColor = UIColor(rgbHexValue: 0x70767d)
    private let recognizeColor = UIColor(rgbHexValue: 0x222222)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadFromXib()
    }
    
    private func loadFromXib() {
        let view = Bundle.main.loadNibNamed("VoiceChromeView", owner: self)?.first as! UIView
        view.frame = bounds
        addSubview(view)
        backgroundView.layer.cornerRadius = 12.0
        backgroundView.layer.borderColor = UIColor(rgbHexValue: 0x000000, alpha: 0.1).cgColor
        backgroundView.layer.borderWidth = 0.5
        backgroundView.clipsToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: -1)
        layer.shadowRadius = 10
    }
}

// MARK: - Public

extension VoiceChromeView {
    func initializeView() {
        topContainerView.isHidden = false
        
        asrStatusView.animation = Animation.named("LP")
        asrStatusView.play()
        asrStatusView.loopMode = .loop
        
        recognizedTextLabel.text = speechGuideText
        recognizedTextLabel.textColor = guideTextColor
    }
    
    func minimize() {
        topContainerView.alpha = 0
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.topContainerView.isHidden = true
            self.frame = CGRect(x: self.frame.origin.x, y: UIScreen.main.bounds.size.height - (92.0 + SampleApp.bottomSafeAreaHeight), width: self.frame.size.width, height: 92.0 + SampleApp.bottomSafeAreaHeight)
            self.stackView.layoutIfNeeded()
        }
    }
    
    func dialogStateDidChange(state: DialogState?) {
        guard let state = state else {
            asrStatusView.animation = nil
            return
        }
        switch state {
        case .listening:
            DispatchQueue.main.async { [weak self] in
                self?.recognizedTextLabel.text = self?.speechGuideText
                self?.recognizedTextLabel.textColor = self?.guideTextColor
                SoundPlayer.playSound(soundType: .start)
                self?.asrStatusView.animation = Animation.named("LP")
                self?.asrStatusView.play()
            }
        case .recognizing:
            DispatchQueue.main.async { [weak self] in
                self?.recognizedTextLabel.text = nil
                self?.recognizedTextLabel.textColor = self?.recognizeColor
                self?.asrStatusView.animation = Animation.named("LA")
                self?.asrStatusView.play()
            }
        case .thinking:
            DispatchQueue.main.async { [weak self] in
                self?.asrStatusView.animation = Animation.named("PC_02")
                self?.asrStatusView.play()
            }
        case .speaking:
            DispatchQueue.main.async { [weak self] in
                self?.asrStatusView.animation = Animation.named("SP_02")
                self?.asrStatusView.play()
            }
        default: break
        }
    }
    
    func asrAgentDidReceive(result: ASRResult) {
        switch result {
        case .complete(let text):
            DispatchQueue.main.async { [weak self] in
                self?.recognizedTextLabel.text = text
                SoundPlayer.playSound(soundType: .success)
            }
        case .partial(let text):
            DispatchQueue.main.async { [weak self] in
                self?.recognizedTextLabel.text = text
            }
        case .error:
            DispatchQueue.main.async { [weak self] in
                self?.asrStatusView.animation = nil
                SoundPlayer.playSound(soundType: .fail)
            }
        default: break
        }
    }
    
    func textAgentDidReceive(result: TextAgentResult) {
        switch result {
        case .complete:
            DispatchQueue.main.async {
                SoundPlayer.playSound(soundType: .success)
            }
        case .error(let textAgentError):
            switch textAgentError {
            case .responseTimeout:
                DispatchQueue.main.async { [weak self] in
                    self?.asrStatusView.animation = nil
                    SoundPlayer.playSound(soundType: .fail)
                }
            }
        }
    }
}

// MARK: - Actions

@objc private extension VoiceChromeView {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
}
