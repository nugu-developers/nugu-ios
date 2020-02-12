//
//  DisplayAudioPlayerView.swift
//  SampleApp
//
//  Created by yonghoonKwon on 20/07/2019.
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

import NuguAgents

final class DisplayAudioPlayerView: UIView {
    
    // MARK: Properties
    
    @IBOutlet private weak var titleContainerView: UIView!
    @IBOutlet private weak var serviceIconImageView: UIImageView!
    @IBOutlet private weak var serviceLabel: UILabel!
    
    @IBOutlet private weak var backgroundImageView: UIImageView!
    
    @IBOutlet private weak var albumImageContainerView: UIView!
    @IBOutlet private weak var albumImageView: UIImageView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitle1Label: UILabel!
    @IBOutlet private weak var subtitle2Label: UILabel!
    
    @IBOutlet private weak var prevButton: UIButton!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    
    @IBOutlet private weak var progressView: UIProgressView!
    
    @IBOutlet private weak var elapsedTimeLabel: UILabel!
    @IBOutlet private weak var durationTimeLabel: UILabel!
    
    private var audioProgressTimer: DispatchSourceTimer?
    private let audioProgressTimerQueue = DispatchQueue(label: "com.sktelecom.romaine.DisplayAudioPlayerView.audioProgress")
    
    var onCloseButtonClick: (() -> Void)?
    
    var displayItem: AudioPlayerDisplayTemplate.AudioPlayer? {
        didSet {
            let template = displayItem?.template
            serviceLabel.text = template?.title.text
            serviceIconImageView.loadImage(from: template?.title.iconUrl)
            
            if let imageUrl = template?.content.imageUrl {
                albumImageView.loadImage(from: imageUrl)
                albumImageContainerView.isHidden = false
            } else {
                albumImageContainerView.isHidden = true
            }
            
            titleLabel.text = template?.content.title
            subtitle1Label.text = template?.content.subtitle ?? template?.content.subtitle1
            subtitle2Label.text = template?.content.subtitle2
            backgroundImageView.loadImage(from: template?.content.backgroundImageUrl)
            
            startProgressTimer()
        }
    }
    
    var audioPlayerState: AudioPlayerState? {
        didSet {
            playPauseButton.isSelected = (audioPlayerState == .playing)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadFromXib()
    }
    
    private func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("DisplayAudioPlayerView", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        albumImageView.layer.cornerRadius = 4.0
        addBorderToTitleContainerView()
    }
    
    private func addBorderToTitleContainerView() {
        titleContainerView.layer.cornerRadius = titleContainerView.bounds.size.height / 2.0
        titleContainerView.layer.borderColor = UIColor(rgbHexValue: 0xc9cacc).cgColor
        titleContainerView.layer.borderWidth = 1.0
    }
}

// MARK: - IBActions

private extension DisplayAudioPlayerView {
    @IBAction private func previousButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.client.getComponent(AudioPlayerAgentProtocol.self)?.prev()
    }
    
    @IBAction private func playPauseDidClick(_ button: UIButton) {
        if button.isSelected {
            NuguCentralManager.shared.client.getComponent(AudioPlayerAgentProtocol.self)?.pause()
        } else {
            NuguCentralManager.shared.client.getComponent(AudioPlayerAgentProtocol.self)?.play()
        }
    }
    
    @IBAction private func nextButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.client.getComponent(AudioPlayerAgentProtocol.self)?.next()
    }
    
    @IBAction private func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
}

// MARK: - Progress Setting

private extension DisplayAudioPlayerView {
    func setAudioPlayerProgress() {
        DispatchQueue.main.async { [weak self] in
            guard let elapsedTimeAsInt = NuguCentralManager.shared.client.getComponent(AudioPlayerAgentProtocol.self)?.offset,
                let durationAsInt = NuguCentralManager.shared.client.getComponent(AudioPlayerAgentProtocol.self)?.duration else {
                    self?.elapsedTimeLabel.text = nil
                    self?.durationTimeLabel.text = nil
                    self?.progressView.isHidden = true
                    return
            }
            let elapsedTime = Float(elapsedTimeAsInt)
            let duration = Float(durationAsInt)
            self?.elapsedTimeLabel.text = Int(elapsedTime).secondTimeString
            self?.durationTimeLabel.text = Int(duration).secondTimeString
            UIView.animate(withDuration: 1.0, animations: { [weak self] in
                self?.progressView.setProgress(elapsedTime/duration, animated: true)
            })
        }
    }
    
    private func startProgressTimer() {
        audioProgressTimer?.cancel()
        audioProgressTimer = DispatchSource.makeTimerSource(queue: audioProgressTimerQueue)
        audioProgressTimer?.schedule(deadline: .now(), repeating: 1.0)
        audioProgressTimer?.setEventHandler(handler: { [weak self] in
            self?.setAudioPlayerProgress()
        })
        audioProgressTimer?.resume()
    }
    
    private func stopProgressTimer() {
        audioProgressTimer?.cancel()
        audioProgressTimer = nil
    }
}
