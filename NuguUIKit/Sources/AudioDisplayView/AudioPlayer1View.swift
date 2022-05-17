//
//  AudioPlayer1View.swift
//  NuguUIKit
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

import NuguUtils
import NuguAgents

final class AudioPlayer1View: AudioDisplayView {
    // Private Properties
    @IBOutlet private weak var nextLyricsLabel: UILabel!
    
    @IBOutlet private weak var badgeImageView: UIImageView!
    @IBOutlet private weak var badgeLabel: UILabel!
    
    private var lyricsTimer: DispatchSourceTimer?
    private let lyricsTimerQueue = DispatchQueue(label: "com.sktelecom.romaine.AudioPlayer1View.lyrics")
    private var lyricsIndex = 0
    
    override var displayPayload: [String: AnyHashable]? {
        didSet {
            guard let displayPayload = displayPayload,
                let payloadData = try? JSONSerialization.data(withJSONObject: displayPayload, options: []),
                let displayItem = try? JSONDecoder().decode(AudioPlayer1Template.self, from: payloadData) else { return }
            
            let template = displayItem.template
            
            titleView.setData(logoUrl: template.title.iconUrl, titleText: template.title.text)
            
            albumImageView.loadImage(from: template.content.imageUrl)
            titleLabel.text = template.content.title
            subtitle1Label.text = template.content.subtitle1
            subtitle2Label.text = template.content.subtitle2
            
            badgeImageView.isHidden = template.content.badgeImageUrl == nil
            badgeImageView.loadImage(from: template.content.badgeImageUrl)
            badgeLabel.text = template.content.badgeMessage
            badgeLabel.isHidden = template.content.badgeMessage == nil
            
            lyricsData = template.content.lyrics
            lyricsStackView.isHidden = lyricsData?.lyricsType == .none
            lyricsStackView.gestureRecognizers?.forEach { lyricsStackView.removeGestureRecognizer($0) }
            let tapGestureRecognizeView = UITapGestureRecognizer(target: self, action: #selector(lyricsViewDidTap(_:)))
            lyricsStackView.addGestureRecognizer(tapGestureRecognizeView)
            lyricsIndex = lyricsData?.lyricsType == "SYNC" ? 0 : -1
            updateLyrics()
            updateFullLyrics()
            
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
            
            if isSeekable {
                startProgressTimer()
                progressView.isHidden = false
                audioPlayerBarView.progressView.isHidden = false
            } else {
                stopProgressTimer()
                elapsedTimeLabel.text = nil
                durationTimeLabel.text = nil
                progressView.isHidden = true
                audioPlayerBarView.progressView.isHidden = true
            }
            
            playPauseButton.isSelected = delegate?.requestAudioPlayerIsPlaying() == true
            audioPlayerBarView.playPauseButton.isSelected = delegate?.requestAudioPlayerIsPlaying() == true
                
            audioPlayerBarView.setData(
                imageUrl: template.content.imageUrl,
                headerText: template.content.title,
                bodyText: template.content.subtitle1
            )
        }
    }
    
    // Initialize
    init(frame: CGRect, isBarModeEnabled: Bool = true) {
        super.init(frame: frame)
        self.isBarModeEnabled = isBarModeEnabled
        
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadFromXib()
    }
    
    private func loadFromXib() {
        // swiftlint:disable force_cast
        #if DEPLOY_OTHER_PACKAGE_MANAGER
        let view = Bundle(for: AudioPlayer1View.self).loadNibNamed("AudioPlayer1View", owner: self)?.first as! UIView
        #else
        let view = Bundle.module.loadNibNamed("AudioPlayer1View", owner: self)?.first as! UIView
        #endif
        // swiftlint:enable force_cast
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        albumImageView.layer.cornerRadius = 8.0
        
        albumImageViewShadowView.layer.shadowColor = UIColor.black.cgColor
        albumImageViewShadowView.layer.shadowOpacity = 0.5
        albumImageViewShadowView.layer.shadowOffset = CGSize(width: 0, height: 5)
        albumImageViewShadowView.layer.shadowRadius = 5
        
        badgeImageView.layer.cornerRadius = badgeImageView.frame.size.height/2
        badgeImageView.layer.borderColor = UIColor(red: 1, green: 58.0/255.0, blue: 0, alpha: 1.0).cgColor
        badgeImageView.layer.borderWidth = 1.5
        
        badgeLabel.layer.cornerRadius = 2.0
        badgeLabel.clipsToBounds = true
        
        titleView.onCloseButtonClick = { [weak self] in
            self?.delegate?.onCloseButtonClick()
        }
        idleBar.onChipsSelect = { [weak self] (selectedChips) in
            self?.delegate?.onChipsSelect(selectedChips: selectedChips)
        }
        idleBar.onNuguButtonClick = { [weak self] in
            self?.delegate?.onNuguButtonClick()
        }
        audioPlayerBarView.delegate = self
        
        barTypeButton.setImage(UIImage(named: "btn_down", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        favoriteButton.setImage(UIImage(named: "btn_like_off", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        favoriteButton.setImage(UIImage(named: "btn_like_on", in: Bundle.imageBundle, compatibleWith: nil), for: .selected)
        prevButton.setImage(UIImage(named: "btn_skip_previous", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        playPauseButton.setImage(UIImage(named: "btn_play", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        playPauseButton.setImage(UIImage(named: "btn_pause", in: Bundle.imageBundle, compatibleWith: nil), for: .selected)
        nextButton.setImage(UIImage(named: "btn_skip_next", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        shuffleButton.setImage(UIImage(named: "btn_random_off", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        shuffleButton.setImage(UIImage(named: "btn_random_on", in: Bundle.imageBundle, compatibleWith: nil), for: .selected)
        
        if isBarModeEnabled {
            setBarMode(0)
        } else {
            setFullMode(0)
        }
        
        theme = UserInterfaceUtil.style == .dark ? .dark : .light
    }
    
    // MARK: - Override (ProgressTimer)
    
    override func startProgressTimer() {
        super.startProgressTimer()
        
        lyricsTimer?.cancel()
        lyricsTimer = DispatchSource.makeTimerSource(queue: lyricsTimerQueue)
        lyricsTimer?.schedule(deadline: .now(), repeating: 0.1)
        lyricsTimer?.setEventHandler(handler: { [weak self] in
            self?.updateLyrics()
        })
        lyricsTimer?.resume()
    }
    
    override func stopProgressTimer() {
        super.stopProgressTimer()
        
        lyricsTimer?.cancel()
        lyricsTimer = nil
    }
    
    // MARK: - Override (Lyrics)
    
    override func updateFullLyrics() {
        super.updateFullLyrics()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.lyricsData == nil || self.lyricsData?.lyricsType == "NONE" {
                self.fullLyricsView.noLyricsLabel.isHidden = false
                return
            }
            self.fullLyricsView.noLyricsLabel.isHidden = true
            if self.lyricsIndex != -1 {
                self.fullLyricsView?.updateLyricsFocus(lyricsIndex: self.lyricsIndex)
            }
        }
    }
    
    override func showLyrics() {
        super.showLyrics()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.lyricsData == nil || self.lyricsData?.lyricsType == "NONE" {
                self.fullLyricsView.noLyricsLabel.isHidden = false
                return
            }
            self.fullLyricsView.noLyricsLabel.isHidden = true
            if self.lyricsIndex != -1 {
                self.fullLyricsView?.updateLyricsFocus(lyricsIndex: self.lyricsIndex)
            }
        }
    }
    
    override func updateLyrics() {
        super.updateLyrics()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let lyricsInfoList = self.lyricsData?.lyricsInfoList,
                  let offSet = self.delegate?.requestOffset(),
                  self.lyricsData?.lyricsType != "NONE" else {
                self.lyricsStackView.isHidden = true
                return
            }
            
            self.lyricsStackView.isHidden = false
                        
            if self.lyricsData?.lyricsType == "NON_SYNC" {
                self.currentLyricsLabel.textColor = UIColor(red: 0, green: 157/255.0, blue: 1, alpha: 1.0)
                if let showButtonText = self.lyricsData?.showButton?.text {
                    self.currentLyricsLabel.text = showButtonText
                } else {
                    self.currentLyricsLabel.text = "전체 가사보기"
                }
                self.nextLyricsLabel.text = nil
                self.fullLyricsView?.updateLyricsFocus(lyricsIndex: nil)
                return
            }
            
            let currentOffSetInMilliseconds = offSet * 1000
            
            guard let firstStartTime = lyricsInfoList.first?.time else { return }
            if currentOffSetInMilliseconds < firstStartTime && self.lyricsIndex != -1 {
                self.lyricsIndex = -1
                self.currentLyricsLabel.textColor = UIColor(red: 136/255.0, green: 136/255.0, blue: 136/255.0, alpha: 1.0)
                self.currentLyricsLabel.text = lyricsInfoList.first?.text
                self.nextLyricsLabel.text = lyricsInfoList[1].text
                self.fullLyricsView?.updateLyricsFocus(lyricsIndex: nil)
                return
            }
            
            guard let lastStartTime = lyricsInfoList.last?.time else { return }
            if currentOffSetInMilliseconds >= lastStartTime && self.lyricsIndex != lyricsInfoList.count - 1 {
                self.lyricsIndex = lyricsInfoList.count - 1
                self.currentLyricsLabel.textColor = UIColor(red: 0, green: 157/255.0, blue: 1, alpha: 1.0)
                self.currentLyricsLabel.text = lyricsInfoList.last?.text
                self.nextLyricsLabel.text = ""
                self.fullLyricsView?.updateLyricsFocus(lyricsIndex: lyricsInfoList.count - 1)
                return
            }
            
            guard let nextLyricsIndex = lyricsInfoList.firstIndex(where: { (lyricsInfo) -> Bool in
                guard let lyricsTime = lyricsInfo.time else { return false }
                return currentOffSetInMilliseconds < lyricsTime
            }) else { return }
            let currentLyricsIndex = nextLyricsIndex - 1
            guard self.lyricsIndex != currentLyricsIndex else { return }
            self.lyricsIndex = currentLyricsIndex
                                    
            self.fullLyricsView?.updateLyricsFocus(lyricsIndex: currentLyricsIndex)
            self.currentLyricsLabel.textColor = UIColor(red: 0, green: 157/255.0, blue: 1, alpha: 1.0)
            self.currentLyricsLabel.text = lyricsInfoList[currentLyricsIndex].text
            self.nextLyricsLabel.text = lyricsInfoList[nextLyricsIndex].text
            
            self.fullLyricsView?.updateLyricsFocus(lyricsIndex: currentLyricsIndex)
        }
    }
}
