//
//  AudioDisplayView.swift
//  NuguUIKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/21.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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

public class AudioDisplayView: UIView {    
    // IBOutlets
    @IBOutlet weak var fullAudioPlayerContainerView: UIView!
    
    @IBOutlet weak var titleView: DisplayTitleView!
        
    @IBOutlet weak var albumImageContainerView: UIView!
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumImageViewShadowView: UIView!
    
    @IBOutlet weak var favoriteButtonContainerView: UIView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitle1Label: UILabel!
    @IBOutlet weak var subtitle2Label: UILabel!
    
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var shuffleButton: UIButton!
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    
    @IBOutlet weak var idleBar: DisplayIdleBar!
    
    @IBOutlet weak var audioPlayerBarViewContainerView: UIView!
    @IBOutlet weak var audioPlayerBarView: AudioPlayerBarView!
    
    // Public Proprties
    public weak var delegate: AudioDisplayViewDelegate?
    public var isBarMode: Bool {
        return audioPlayerBarViewContainerView.isHidden == false
    }
    public var isLyricsVisible: Bool {
        return false
    }
    public var audioPlayerState: AudioPlayerState? {
        didSet {
            playPauseButton.isSelected = (audioPlayerState == .playing)
            audioPlayerBarView.playPauseButton.isSelected = (audioPlayerState == .playing)
        }
    }
    
    // Internal Properties
    var isSeekable: Bool = false
    var displayPayload: [String: AnyHashable]?
    var repeatMode: AudioPlayerDisplayRepeat? {
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
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        delegate?.onUserInteraction()
        return super.hitTest(point, with: event)
    }
    
    // Overridable Public Methods    
    public func shouldShowLyrics() -> Bool {
        return false
    }
    
    public func shouldHideLyrics() -> Bool {
        return false
    }
}

// MARK: - Public Methods

public extension AudioDisplayView {
    static func makeDisplayAudioPlayerView(audioPlayerDisplayTemplate: AudioPlayerDisplayTemplate, frame: CGRect) -> AudioDisplayView? {
        let displayAudioPlayerView: AudioDisplayView?
        
        switch audioPlayerDisplayTemplate.type {
        case "AudioPlayer.Template1":
            displayAudioPlayerView = AudioPlayer1View(frame: frame)
        case "AudioPlayer.Template2":
            displayAudioPlayerView = AudioPlayer2View(frame: frame)
        default:
            displayAudioPlayerView = nil
        }
        displayAudioPlayerView?.isSeekable = audioPlayerDisplayTemplate.isSeekable
        displayAudioPlayerView?.displayPayload = audioPlayerDisplayTemplate.payload
        return displayAudioPlayerView
    }
    
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
        
    func setBarMode() {
        audioPlayerBarViewContainerView.isHidden = false
        fullAudioPlayerContainerView.isHidden = true
        frame = CGRect(origin: CGPoint(x: 0, y: frame.size.height - 58.0 - SafeAreaUtil.bottomSafeAreaHeight), size: audioPlayerBarViewContainerView.frame.size)
    }
}

// MARK: - IBActions

extension AudioDisplayView {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        delegate?.onCloseButtonClick()
    }
    
    @IBAction func barTypeButtonDidClick(_ button: UIButton) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.setBarMode()
        }
    }
    
    @IBAction func previousButtonDidClick(_ button: UIButton) {
        delegate?.onPreviousButtonClick()
    }
    
    @IBAction func playPauseDidClick(_ button: UIButton) {
        if button.isSelected {
            delegate?.onPauseButtonClick()
        } else {
            delegate?.onPlayButtonClick()
        }
    }
    
    @IBAction func nextButtonDidClick(_ button: UIButton) {
        delegate?.onNextButtonClick()
    }
    
    @IBAction func favoriteButtonDidClick(_ button: UIButton) {
        delegate?.onFavoriteButtonClick(current: favoriteButton.isSelected)
    }
    
    @IBAction func repeatButtonDidClick(_ button: UIButton) {
        guard let repeatMode = repeatMode else { return }
        delegate?.onRepeatButtonDidClick(currentMode: repeatMode)
    }
    
    @IBAction func shuffleButtonDidClick(_ button: UIButton) {
        delegate?.onShuffleButtonDidClick(current: shuffleButton.isSelected)
    }
}

// MARK: - AudioPlayerBarViewDelegate

extension AudioDisplayView: AudioPlayerBarViewDelegate {
    func onViewTap() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: UIScreen.main.bounds.size)
            self.fullAudioPlayerContainerView.isHidden = false
            self.audioPlayerBarViewContainerView.isHidden = true
        }
    }
    
    func onCloseButtonClick() {
        delegate?.onCloseButtonClick()
    }
    
    func onPreviousButtonClick() {
        delegate?.onPreviousButtonClick()
    }
    
    func onPlayButtonClick() {
        delegate?.onPlayButtonClick()
    }
    
    func onPauseButtonClick() {
        delegate?.onPauseButtonClick()
    }
    
    func onNextButtonClick() {
        delegate?.onNextButtonClick()
    }
    
    func requestOffset() -> Int? {
        return delegate?.requestOffset()
    }
    
    func requestDuration() -> Int? {
        return delegate?.requestDuration()
    }
}
