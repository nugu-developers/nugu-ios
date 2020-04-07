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
    
    @IBOutlet private weak var favoriteButtonContainerView: UIView!
    @IBOutlet private weak var favoriteButton: UIButton!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitle1Label: UILabel!
    @IBOutlet private weak var subtitle2Label: UILabel!
    
    @IBOutlet private weak var repeatButton: UIButton!
    @IBOutlet private weak var prevButton: UIButton!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var shuffleButton: UIButton!
    
    @IBOutlet private weak var progressView: UIProgressView!
    
    @IBOutlet private weak var elapsedTimeLabel: UILabel!
    @IBOutlet private weak var durationTimeLabel: UILabel!
    
    private var audioProgressTimer: DispatchSourceTimer?
    private let audioProgressTimerQueue = DispatchQueue(label: "com.sktelecom.romaine.DisplayAudioPlayerView.audioProgress")
    
    var onCloseButtonClick: (() -> Void)?
    
    var onUserInteraction: (() -> Void)?
    
    var displayPayload: [String: AnyHashable]? {
        didSet {
            guard let displayPayload = displayPayload,
                let payloadData = try? JSONSerialization.data(withJSONObject: displayPayload, options: []),
                let displayItem = try? JSONDecoder().decode(AudioPlayerTemplate.self, from: payloadData) else { return }
            
            let template = displayItem.template
            serviceLabel.text = template.title.text
            serviceIconImageView.loadImage(from: template.title.iconUrl)
            albumImageView.loadImage(from: template.content.imageUrl)
            titleLabel.text = template.content.title
            subtitle1Label.text = template.content.subtitle ?? template.content.subtitle1
            subtitle2Label.text = template.content.subtitle2
            backgroundImageView.loadImage(from: template.content.backgroundImageUrl)
            
            if let favorite = template.content.settings?.favorite {
                favoriteButtonContainerView.isHidden = false
                favoriteButton.isSelected = favorite
            } else {
                favoriteButtonContainerView.isHidden = true
            }
            
            if let `repeat` = template.content.settings?.repeat {
                repeatButton.isHidden = false
                repeatMode = `repeat`
            } else {
                repeatButton.isHidden = true
            }
            
            if let shuffle = template.content.settings?.shuffle {
                shuffleButton.isHidden = false
                shuffleButton.isSelected = shuffle
            } else {
                shuffleButton.isHidden = true
            }
            
            startProgressTimer()
        }
    }
    
    var audioPlayerState: AudioPlayerState? {
        didSet {
            playPauseButton.isSelected = (audioPlayerState == .playing)
        }
    }
    
    private var repeatMode: AudioPlayerDisplayRepeat? {
        didSet {
            guard let repeatMode = repeatMode else { return }
            switch repeatMode {
            case .all:
                repeatButton.setImage(UIImage(named: "btn_repeat_on"), for: .normal)
            case .one:
                repeatButton.setImage(UIImage(named: "btn_repeat_1_on"), for: .normal)
            case .none:
                repeatButton.setImage(UIImage(named: "btn_repeat_off"), for: .normal)
            }
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
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        onUserInteraction?()
        return super.hitTest(point, with: event)
    }
    
    private func addBorderToTitleContainerView() {
        titleContainerView.layer.cornerRadius = titleContainerView.bounds.size.height / 2.0
        titleContainerView.layer.borderColor = UIColor(rgbHexValue: 0xc9cacc).cgColor
        titleContainerView.layer.borderWidth = 1.0
    }
}

// MARK: - Update

extension DisplayAudioPlayerView {
    func updateSettings(payload: Data) {
        guard let payload = try? JSONDecoder().decode(AudioPlayerUpdateMetadataPayload.self, from: payload) else {
                log.error("invalid payload")
                return
        }
        
        if let favorite = payload.metadata?.template?.content?.settings?.favorite {
            favoriteButtonContainerView.isHidden = false
            favoriteButton.isSelected = favorite
        }
        
        if let `repeat` = payload.metadata?.template?.content?.settings?.repeat {
            repeatButton.isHidden = false
            repeatMode = `repeat`
        }
        
        if let shuffle = payload.metadata?.template?.content?.settings?.shuffle {
            shuffleButton.isHidden = false
            shuffleButton.isSelected = shuffle
        }
    }
}

// MARK: - IBActions

private extension DisplayAudioPlayerView {
    @IBAction func previousButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.client.audioPlayerAgent.prev()
    }
    
    @IBAction func playPauseDidClick(_ button: UIButton) {
        if button.isSelected {
            NuguCentralManager.shared.client.audioPlayerAgent.pause()
        } else {
            NuguCentralManager.shared.client.audioPlayerAgent.play()
        }
    }
    
    @IBAction func nextButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.client.audioPlayerAgent.next()
    }
    
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
    
    @IBAction func favoriteButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.client.audioPlayerAgent.favorite(isOn: favoriteButton.isSelected)
        favoriteButton.isSelected = !favoriteButton.isSelected
    }
    
    @IBAction func repeatButtonDidClick(_ button: UIButton) {
        guard let repeatMode = repeatMode else { return }
        NuguCentralManager.shared.client.audioPlayerAgent.repeat(mode: repeatMode)
        switch repeatMode {
        case .all:
            self.repeatMode = AudioPlayerDisplayRepeat.one
        case .one:
            self.repeatMode = AudioPlayerDisplayRepeat.none
        case .none:
            self.repeatMode = AudioPlayerDisplayRepeat.all
        }
    }
    
    @IBAction func shuffleButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.client.audioPlayerAgent.shuffle(isOn: shuffleButton.isSelected)
        shuffleButton.isSelected = !shuffleButton.isSelected
    }
}

// MARK: - Progress Setting

private extension DisplayAudioPlayerView {
    func setAudioPlayerProgress() {
        DispatchQueue.main.async { [weak self] in
            guard let elapsedTimeAsInt = NuguCentralManager.shared.client.audioPlayerAgent.offset,
                let durationAsInt = NuguCentralManager.shared.client.audioPlayerAgent.duration else {
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
