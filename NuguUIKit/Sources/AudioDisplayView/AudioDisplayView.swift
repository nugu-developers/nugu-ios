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
import NuguUtils

/// <#Description#>
public class AudioDisplayView: UIView {    
    // IBOutlets
    @IBOutlet weak var barTypeButton: UIButton!
    
    @IBOutlet weak var fullAudioPlayerContainerView: UIView!
    
    @IBOutlet weak var titleView: DisplayTitleView!
        
    @IBOutlet weak var albumImageContainerView: UIView!
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumImageViewShadowView: UIView!
    
    @IBOutlet weak var contentStackView: UIStackView!
    
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
    
    @IBOutlet weak var lyricsStackView: UIStackView!
    @IBOutlet weak var currentLyricsLabel: UILabel!
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    
    @IBOutlet weak var idleBar: DisplayIdleBar!
    @IBOutlet private weak var idleBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var audioPlayerBarViewContainerView: UIView!
    @IBOutlet weak var audioPlayerBarView: AudioPlayerBarView!
    
    @IBOutlet weak var fullLyricsView: FullLyricsView!
    
    // Public Proprties
    public weak var delegate: AudioDisplayViewDelegate?
    public var isBarMode: Bool {
        return audioPlayerBarViewContainerView.isHidden == false
    }
    public var isLyricsVisible: Bool {
        if isBarMode == true {
            return false
        }
        return fullLyricsView.isHidden == false
    }
    public var audioPlayerState: AudioPlayerState? {
        didSet {
            playPauseButton.isSelected = (audioPlayerState == .playing)
            audioPlayerBarView.playPauseButton.isSelected = (audioPlayerState == .playing)
        }
    }
    
    public var displayPayload: [String: AnyHashable]?
    public var isSeekable: Bool = false
    public var isBarModeEnabled: Bool = true
    public var isNuguButtonShow: Bool = true {
        didSet {
            idleBarHeightConstraint.constant = (isNuguButtonShow ? 68.0 : 0)
        }
    }
    
    public var theme: AudioDisplayTheme = UserInterfaceUtil.style == .dark ? .dark : .light {
        didSet {
            fullAudioPlayerContainerView.backgroundColor = theme.backgroundColor
            audioPlayerBarViewContainerView.backgroundColor = theme.barPlayerBackgroundColor
            audioPlayerBarView.subviews.first?.backgroundColor = theme.barPlayerBackgroundColor
            audioPlayerBarView.headerLabel.textColor = theme.titleLabelTextColor
            titleView.titleLabel.textColor = theme.titleViewTextColor
            titleLabel.textColor = theme.titleLabelTextColor
            subtitle1Label.textColor = theme.subTitleLabelTextColor
            progressView.trackTintColor = theme.progressViewTrackTintColor
            audioPlayerBarView.progressView.trackTintColor = theme.barProgressViewTrackTintColor
            fullLyricsView.theme = theme
            idleBar.chipsView.theme = (theme == .light) ? .light : .dark
            playPauseButton.setImage(theme.playImage, for: .normal)
            playPauseButton.setImage(theme.pauseImage, for: .selected)
            nextButton.setImage(theme.nextImage, for: .normal)
            prevButton.setImage(theme.prevImage, for: .normal)
            audioPlayerBarView.playPauseButton.setImage(theme.playImage, for: .normal)
            audioPlayerBarView.playPauseButton.setImage(theme.pauseImage, for: .selected)
            audioPlayerBarView.nextButton.setImage(theme.nextImage, for: .normal)
            audioPlayerBarView.prevButton.setImage(theme.prevImage, for: .normal)
        }
    }
    
    // Internal Properties
    var lyricsData: AudioPlayerLyricsTemplate?

    var repeatMode: AudioPlayerDisplayRepeat? {
        didSet {
            guard let repeatMode = repeatMode else { return }
            switch repeatMode {
            case .all:
                repeatButton.setImage(UIImage(named: "btn_repeat_on", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
            case .one:
                repeatButton.setImage(UIImage(named: "btn_repeat_1_on", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
            case .none:
                repeatButton.setImage(UIImage(named: "btn_repeat_off", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
            }
        }
    }
    
    // Private Properties
    private var audioProgressTimer: DispatchSourceTimer?
    private let audioProgressTimerQueue = DispatchQueue(label: "com.sktelecom.romaine.AudioDisplayView.audioProgress")
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        delegate?.onUserInteraction()
        return super.hitTest(point, with: event)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()

        // Theme should be updated when theme value has been changed,
        // Because of progressView's missing context issue (fails to update it's tint color on not appearing state)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let themeToUpdate = self.theme
            self.theme = themeToUpdate
        }
    }
    
    // Overridable Public Methods    
    public func shouldShowLyrics() -> Bool {
        guard isBarMode == false else {
            return false
        }
        showLyrics()
        return true
    }
    
    public func shouldHideLyrics() -> Bool {
        guard isBarMode == false else {
            return false
        }
        fullLyricsView.isHidden = true
        fullAudioPlayerContainerView.sendSubviewToBack(fullLyricsView)
        contentStackView.isHidden = false
        return true
    }
    
    // MARK: - Progress Setting
    
    func setAudioPlayerProgress() {
        DispatchQueue.main.async { [weak self] in
            guard let elapsedTimeAsInt = self?.delegate?.requestOffset(),
                  let durationAsInt = self?.delegate?.requestDuration() else {
                self?.elapsedTimeLabel.text = nil
                self?.durationTimeLabel.text = nil
                self?.progressView.isHidden = true
                self?.audioPlayerBarView.progressView.isHidden = true
                return
            }
            self?.progressView.isHidden = false
            self?.audioPlayerBarView.progressView.isHidden = false
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
    }
    
    func stopProgressTimer() {
        audioProgressTimer?.cancel()
        audioProgressTimer = nil
    }
    
    // MARK: - Lyrics
    
    @objc func lyricsViewDidTap(_ gestureRecognizer: UITapGestureRecognizer) {
        showLyrics()
    }
    
    func updateFullLyrics() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.fullLyricsView.stackView.arrangedSubviews.filter { $0.isKind(of: UILabel.self) }.forEach { $0.removeFromSuperview() }
            self.fullLyricsView.headerLabel.text = self.lyricsData?.title
            self.lyricsData?.lyricsInfoList.forEach { lyricsInfo in
                let label = UILabel()
                label.numberOfLines = 0
                label.textAlignment = .center
                label.text = lyricsInfo.text
                label.font = UIFont.systemFont(ofSize: 16)
                label.textColor = UIColor(red: 68.0/255.0, green: 68.0/255.0, blue: 68.0/255.0, alpha: 1.0)
                self.fullLyricsView.stackView.addArrangedSubview(label)
            }
            self.fullLyricsView.scrollView.setContentOffset(.zero, animated: true)
            self.fullLyricsView.theme = self.theme
        }
    }
    
    func showLyrics() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.contentStackView.isHidden = true
            self.updateFullLyrics()
            self.fullLyricsView.onViewDidTap = { [weak self] in
                guard let self = self else { return }
                self.fullLyricsView.isHidden = true
                self.fullAudioPlayerContainerView.sendSubviewToBack(self.fullLyricsView)
                self.contentStackView.isHidden = false
            }
            self.fullLyricsView.isHidden = false
            self.fullAudioPlayerContainerView.bringSubviewToFront(self.fullLyricsView)
        }
    }
    
    func updateLyrics() {}
}

// MARK: - Public Methods

public extension AudioDisplayView {
    static func audioPlayerViewType(audioPlayerDisplayTemplate: AudioPlayerDisplayTemplate) -> AudioDisplayView.Type? {
        switch audioPlayerDisplayTemplate.type {
        case "AudioPlayer.Template1":
            return AudioPlayer1View.self
        default:
            return nil
        }
    }
    
    static func makeDisplayAudioPlayerView(audioPlayerDisplayTemplate: AudioPlayerDisplayTemplate, frame: CGRect, isBarModeEnabled: Bool = true) -> AudioDisplayView? {
        let displayAudioPlayerView: AudioDisplayView?
        
        switch audioPlayerDisplayTemplate.type {
        case "AudioPlayer.Template1":
            displayAudioPlayerView = AudioPlayer1View(frame: frame, isBarModeEnabled: isBarModeEnabled)
        default:
            displayAudioPlayerView = nil
        }
        displayAudioPlayerView?.isSeekable = audioPlayerDisplayTemplate.isSeekable
        return displayAudioPlayerView
    }
    
    func updateSettings(payload: AudioPlayerUpdateMetadataPayload) {
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
        
    func setBarMode(_ duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration) { [weak self] in
            guard let self = self else { return }
            self.audioPlayerBarViewContainerView.isHidden = false
            self.audioPlayerBarViewContainerView.alpha = 1.0
            
            self.fullAudioPlayerContainerView.transform = CGAffineTransform(
                translationX: 0.0,
                y: self.fullAudioPlayerContainerView.bounds.height
            )
            self.fullAudioPlayerContainerView.alpha = 0.0
        } completion: { [weak self] _ in
            self?.fullAudioPlayerContainerView.isHidden = true
        }
    }
    
    func setFullMode(_ duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration) { [weak self] in
            guard let self = self else { return }
            self.fullAudioPlayerContainerView.isHidden = false
            self.audioPlayerBarViewContainerView.alpha = 0.0

            self.fullAudioPlayerContainerView.transform = CGAffineTransform(
                translationX: 0.0,
                y: 0
            )
            self.fullAudioPlayerContainerView.alpha = 1.0
        } completion: { [weak self] _ in
            self?.audioPlayerBarViewContainerView.isHidden = true
        }
    }
}

// MARK: - IBActions

extension AudioDisplayView {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        delegate?.onCloseButtonClick()
    }
    
    @IBAction func barTypeButtonDidClick(_ button: UIButton) {
        if isBarModeEnabled {
            self.setBarMode()
        }
        
        delegate?.onBarTypeButtonClick()
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
        self.setFullMode()
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
