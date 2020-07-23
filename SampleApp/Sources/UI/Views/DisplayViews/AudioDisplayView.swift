//
//  AudioDisplayView.swift
//  SampleApp
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
import NuguUIKit

class AudioDisplayView: UIView {
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
    
    var isBarMode: Bool {
        return audioPlayerBarViewContainerView.isHidden == false
    }
    
    var isLyricsVisible: Bool {
        return false
    }
    
    var onCloseButtonClick: (() -> Void)?
    var onUserInteraction: (() -> Void)?    
    var onNuguButtonClick: (() -> Void)? {
        didSet {
            idleBar.onNuguButtonClick = onNuguButtonClick
        }
    }
    var onChipsSelect: ((_ text: String?) -> Void)? {
        didSet {
            idleBar.onChipsSelect = onChipsSelect
        }
    }
    
    var displayPayload: [String: AnyHashable]?
    var audioPlayerState: AudioPlayerState? {
        didSet {
            playPauseButton.isSelected = (audioPlayerState == .playing)
            audioPlayerBarView.playPauseButton.isSelected = (audioPlayerState == .playing)
        }
    }
    
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
    
    // MARK: - Update
    
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
    
    // MARK: - Show / Hide lyrics
    
    func shouldShowLyrics() -> Bool {
        return false
    }
    
    func shouldHideLyrics() -> Bool {
        return false
    }
    
    func setBarMode() {
        audioPlayerBarViewContainerView.isHidden = false
        fullAudioPlayerContainerView.isHidden = true
        frame = CGRect(origin: CGPoint(x: 0, y: frame.size.height - 58.0 - SampleApp.bottomSafeAreaHeight), size: audioPlayerBarViewContainerView.frame.size)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        onUserInteraction?()
        return super.hitTest(point, with: event)
    }
}

extension AudioDisplayView {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
    
    @IBAction func barTypeButtonDidClick(_ button: UIButton) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.setBarMode()
        }
    }
    
    @IBAction func previousButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.client.audioPlayerAgent.prev()
    }
    
    @IBAction func playPauseDidClick(_ button: UIButton) {
        if button.isSelected {
            NuguCentralManager.shared.client.audioPlayerAgent.pause()
        } else {
            NuguCentralManager.shared.client.ttsAgent.stopTTS()
            NuguCentralManager.shared.client.audioPlayerAgent.play()
        }
    }
    
    @IBAction func nextButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.client.audioPlayerAgent.next()
    }
    
    @IBAction func favoriteButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.client.audioPlayerAgent.requestFavoriteCommand(current: favoriteButton.isSelected)
        favoriteButton.isSelected = !favoriteButton.isSelected
    }
    
    @IBAction func repeatButtonDidClick(_ button: UIButton) {
        guard let repeatMode = repeatMode else { return }
        NuguCentralManager.shared.client.audioPlayerAgent.requestRepeatCommand(currentMode: repeatMode)
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
        NuguCentralManager.shared.client.audioPlayerAgent.requestShuffleCommand(current: shuffleButton.isSelected)
        shuffleButton.isSelected = !shuffleButton.isSelected
    }
}
