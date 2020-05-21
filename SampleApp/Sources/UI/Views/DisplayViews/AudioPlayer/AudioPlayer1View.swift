//
//  AudioPlayer1View.swift
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
import NuguUIKit

final class AudioPlayer1View: UIView {
    
    // MARK: Properties
    
    @IBOutlet private weak var fullAudioPlayerContainerView: UIView!
    
    @IBOutlet private weak var titleView: DisplayTitleView!
    
    @IBOutlet private weak var contentStackView: UIStackView!
    
    @IBOutlet private weak var albumImageContainerView: UIView!
    @IBOutlet private weak var albumImageView: UIImageView!
    @IBOutlet private weak var albumImageViewShadowView: UIView!
    @IBOutlet private weak var adultContentLabel: UILabel!
    @IBOutlet private weak var preListenContainerView: UIView!
    
    @IBOutlet private weak var favoriteButtonContainerView: UIView!
    @IBOutlet private weak var favoriteButton: UIButton!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitle1Label: UILabel!
    @IBOutlet private weak var subtitle2Label: UILabel!
    
    @IBOutlet private weak var lyricsView: UIView!
    @IBOutlet private weak var currentLyricsLabel: UILabel!
    @IBOutlet private weak var nextLyricsLabel: UILabel!
    
    @IBOutlet private weak var repeatButton: UIButton!
    @IBOutlet private weak var prevButton: UIButton!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var shuffleButton: UIButton!
    
    @IBOutlet private weak var progressView: UIProgressView!
    
    @IBOutlet private weak var elapsedTimeLabel: UILabel!
    @IBOutlet private weak var durationTimeLabel: UILabel!
    
    @IBOutlet private weak var idleBar: DisplayIdleBar!
    
    @IBOutlet private weak var audioPlayerBarViewContainerView: UIView!
    @IBOutlet private weak var audioPlayerBarView: AudioPlayerBarView!
    
    private var audioProgressTimer: DispatchSourceTimer?
    private let audioProgressTimerQueue = DispatchQueue(label: "com.sktelecom.romaine.DisplayAudioPlayerView.audioProgress")
    
    private var lyricsTimer: DispatchSourceTimer?
    private let lyricsTimerQueue = DispatchQueue(label: "com.sktelecom.romaine.DisplayAudioPlayerView.lyrics")
    private var lyricsData: AudioPlayerLyricsTemplate?
    private var lyricsIndex = 0
    
    private var fullLyricsView: FullLyricsView?
    
    var isBarMode: Bool {
        return audioPlayerBarViewContainerView.isHidden == false
    }
    
    var onCloseButtonClick: (() -> Void)?
    
    var onUserInteraction: (() -> Void)?
    
    var displayPayload: [String: AnyHashable]? {
        didSet {
            guard let displayPayload = displayPayload,
                let payloadData = try? JSONSerialization.data(withJSONObject: displayPayload, options: []),
                let displayItem = try? JSONDecoder().decode(AudioPlayer1Template.self, from: payloadData) else { return }
            
            let template = displayItem.template
            
            titleView.setData(titleData: template.title)
            
            albumImageView.loadImage(from: template.content.imageUrl)
            titleLabel.text = template.content.title
            subtitle1Label.text = template.content.subtitle1
            subtitle2Label.text = template.content.subtitle2
            
            lyricsData = template.content.lyrics
            lyricsView.isHidden = lyricsData?.lyricsType == .none
            lyricsView.gestureRecognizers?.forEach { lyricsView.removeGestureRecognizer($0) }
            let tapGestureRecognizeView = UITapGestureRecognizer(target: self, action: #selector(lyricsViewDidTap(_:)))
            lyricsView.addGestureRecognizer(tapGestureRecognizeView)
            
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
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = template.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
            
            startProgressTimer()
            audioPlayerBarView.displayPayload = displayPayload
            audioPlayerBarView.onCloseButtonClick = { [weak self] in
                self?.onCloseButtonClick?()
            }
            audioPlayerBarView.onViewDidTap = { [weak self] in
                UIView.animate(withDuration: 0.3) { [weak self] in
                    guard let self = self else { return }
                    self.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: UIScreen.main.bounds.size)
                    self.fullAudioPlayerContainerView.isHidden = false
                    self.audioPlayerBarViewContainerView.isHidden = true
                }
            }
        }
    }
    
    var audioPlayerState: AudioPlayerState? {
        didSet {
            playPauseButton.isSelected = (audioPlayerState == .playing)
            audioPlayerBarView.playPauseButton.isSelected = (audioPlayerState == .playing)
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
        let view = Bundle.main.loadNibNamed("AudioPlayer1View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        albumImageView.layer.cornerRadius = 8.0
        
        albumImageViewShadowView.layer.shadowColor = UIColor.black.cgColor
        albumImageViewShadowView.layer.shadowOpacity = 0.5
        albumImageViewShadowView.layer.shadowOffset = CGSize(width: 0, height: 5)
        albumImageViewShadowView.layer.shadowRadius = 5
        
        adultContentLabel.layer.cornerRadius = adultContentLabel.frame.size.height/2
        adultContentLabel.layer.borderColor = UIColor(red: 1, green: 58.0/255.0, blue: 0, alpha: 1.0).cgColor
        adultContentLabel.layer.borderWidth = 1.5
        
        preListenContainerView.layer.cornerRadius = 2.0
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        onUserInteraction?()
        return super.hitTest(point, with: event)
    }
}

// MARK: - Update

extension AudioPlayer1View {
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

private extension AudioPlayer1View {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
    
    @IBAction func barTypeButtonDidClick(_ button: UIButton) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.audioPlayerBarViewContainerView.isHidden = false
            self.fullAudioPlayerContainerView.isHidden = true
            self.frame = CGRect(origin: CGPoint(x: 0, y: self.frame.size.height - 58.0 - SampleApp.bottomSafeAreaHeight), size: self.audioPlayerBarViewContainerView.frame.size)
        }
    }
    
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
    
    @objc func lyricsViewDidTap(_ gestureRecognizer: UITapGestureRecognizer) {
        fullLyricsView = FullLyricsView(frame: contentStackView.frame)
        fullLyricsView?.headerLabel.text = lyricsData?.title
        lyricsData?.lyricsInfoList.forEach { lyricsInfo in
            let label = UILabel()
            label.textAlignment = .center
            label.text = lyricsInfo.text
            label.font = UIFont.systemFont(ofSize: 16)
            label.textColor = UIColor(red: 68.0/255.0, green: 68.0/255.0, blue: 68.0/255.0, alpha: 1.0)
            fullLyricsView?.stackView.addArrangedSubview(label)
        }
        fullLyricsView?.onViewDidTap = { [weak self] in
            self?.fullLyricsView?.removeFromSuperview()
        }
        if let fullLyricsView = fullLyricsView {
            fullAudioPlayerContainerView.addSubview(fullLyricsView)
        }
    }
}

// MARK: - Progress Setting

private extension AudioPlayer1View {
    func updateLyrics() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let lyricsInfoList = self.lyricsData?.lyricsInfoList,
                let offSet = NuguCentralManager.shared.client.audioPlayerAgent.offset,
                self.lyricsData?.lyricsType != "NONE" else {
                    self.lyricsView.isHidden = true
                    return
            }
            
            self.lyricsView.isHidden = false
            
            if self.lyricsData?.lyricsType == "NON_SYNC" {
                self.currentLyricsLabel.textColor = UIColor(red: 0, green: 157/255.0, blue: 1, alpha: 1.0)
                self.currentLyricsLabel.text = "전체 가사보기"
                self.nextLyricsLabel.text = nil
                return
            }
            
            if self.lyricsIndex >= lyricsInfoList.count {
                self.lyricsIndex = 0
                return
            }
            
            let offSetInMilliseconds = offSet * 1000
            let currentLyrics = lyricsInfoList[self.lyricsIndex].text
            let nextLyrics = self.lyricsIndex+1 >= lyricsInfoList.count ? "" : lyricsInfoList[self.lyricsIndex+1].text
            
            if lyricsInfoList[self.lyricsIndex].time > offSetInMilliseconds {
                self.currentLyricsLabel.textColor = UIColor(red: 136/255.0, green: 136/255.0, blue: 136/255.0, alpha: 1.0)
                self.currentLyricsLabel.text = currentLyrics
                self.nextLyricsLabel.text = nextLyrics
            } else if self.lyricsIndex >= lyricsInfoList.count - 1 {
                self.currentLyricsLabel.text = currentLyrics
                self.nextLyricsLabel.text = nextLyrics
            } else if lyricsInfoList[self.lyricsIndex].time <= offSetInMilliseconds && lyricsInfoList[self.lyricsIndex + 1].time > offSetInMilliseconds {
                self.currentLyricsLabel.textColor = UIColor(red: 0, green: 157/255.0, blue: 1, alpha: 1.0)
                self.currentLyricsLabel.text = currentLyrics
                self.nextLyricsLabel.text = nextLyrics
                self.fullLyricsView?.updateLyricsFocus(lyricsIndex: self.lyricsIndex)
            } else {
                self.lyricsIndex += 1
                self.updateLyrics()
            }
        }
    }
    
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
                let progress = duration == 0 ? 0 : elapsedTime/duration
                self?.progressView.setProgress(progress, animated: true)
            })
        }
    }
    
    func startProgressTimer() {
        audioProgressTimer?.cancel()
        audioProgressTimer = DispatchSource.makeTimerSource(queue: audioProgressTimerQueue)
        audioProgressTimer?.schedule(deadline: .now(), repeating: 1.0)
        audioProgressTimer?.setEventHandler(handler: { [weak self] in
            self?.setAudioPlayerProgress()
        })
        audioProgressTimer?.resume()
        
        lyricsTimer?.cancel()
        lyricsTimer = DispatchSource.makeTimerSource(queue: lyricsTimerQueue)
        lyricsTimer?.schedule(deadline: .now(), repeating: 0.1)
        lyricsTimer?.setEventHandler(handler: { [weak self] in
            self?.updateLyrics()
        })
        lyricsTimer?.resume()
    }
    
    func stopProgressTimer() {
        audioProgressTimer?.cancel()
        audioProgressTimer = nil
        lyricsTimer?.cancel()
        lyricsTimer = nil
    }
}
