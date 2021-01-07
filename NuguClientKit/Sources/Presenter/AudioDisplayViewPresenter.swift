//
//  AudioDisplayViewPresenter.swift
//  NuguClientKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/12/23.
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

import Foundation
import UIKit

import NuguAgents
import NuguUIKit
import NuguCore

/// AudioDisplayViewPresenter is a class which helps user for displaying AudioDisplayView more easily.
public class AudioDisplayViewPresenter {

    public weak var delegate: AudioDisplayViewPresenterDelegate?
    
    private var audioDisplayView: AudioDisplayView?
    private weak var viewController: UIViewController?
    private weak var superView: UIView?
    private var targetView: UIView? {
        superView ?? viewController?.view
    }
    private var nuguClient: NuguClient?
    
    /// Initialize with superView
    /// - Parameters:
    ///   - superView: Target view for AudioDisplayView should be added to.
    ///   - nuguClient: NuguClient instance which should be passed for delegation.
    public convenience init(superView: UIView, nuguClient: NuguClient) {
        self.init(nuguClient: nuguClient)
        self.superView = superView
    }
    
    /// Initialize with viewController
    /// - Parameters:
    ///   - viewController: Target viewController for AudioDisplayView should be added to.
    ///   - nuguClient: NuguClient instance which should be passed for delegation.
    public convenience init(viewController: UIViewController, nuguClient: NuguClient) {
        self.init(nuguClient: nuguClient)
        self.viewController = viewController
    }
    
    /// Initialize
    /// - Parameters:
    ///   - nuguClient: NuguClient instance which should be passed for delegation.
    private init(nuguClient: NuguClient) {
        self.nuguClient = nuguClient
        
        nuguClient.audioPlayerAgent.displayDelegate = self
        
        // Observers
        nuguClient.audioPlayerAgent.audioPlayerStateObserverContainer.addObserver { [weak self] (state, additionalInfo) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                    let audioDisplayView = self.audioDisplayView else { return }
                audioDisplayView.audioPlayerState = state
                self.delegate?.displayControllerShouldUpdateState(state: state)
            }
        }
        
        nuguClient.audioPlayerAgent.audioPlayerDurationObserverContainer.addObserver { [weak self] (duration, additionalInfo) in
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.displayControllerShouldUpdateDuration(duration: duration)
            }
        }
    }
}

// MARK: - AudioPlayerDisplayDelegate

extension AudioDisplayViewPresenter: AudioPlayerDisplayDelegate {
    public func audioPlayerDisplayShouldRender(template: AudioPlayerDisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.addDisplayAudioPlayerView(audioPlayerDisplayTemplate: template, completion: completion)
            self?.delegate?.displayControllerShouldUpdateTemplate(template: template)
        }
    }
    
    public func audioPlayerDisplayDidClear(template: AudioPlayerDisplayTemplate) {
        DispatchQueue.main.async { [weak self] in
            self?.dismissDisplayAudioPlayerView()
            self?.delegate?.displayControllerShouldRemove()
        }
    }
    
    public func audioPlayerDisplayShouldUpdateMetadata(payload: Data, header: Downstream.Header) {
        DispatchQueue.main.async { [weak self] in
            self?.audioDisplayView?.updateSettings(payload: payload)
        }
    }
    
    public func audioPlayerDisplayShouldShowLyrics(header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            completion(self?.audioDisplayView?.shouldShowLyrics() ?? false)
        }
    }
    
    public func audioPlayerDisplayShouldHideLyrics(header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            completion(self?.audioDisplayView?.shouldHideLyrics() ?? false)
        }
    }
    
    public func audioPlayerDisplayShouldControlLyricsPage(direction: AudioPlayerDisplayControlPayload.Direction, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            completion(false)
        }
    }
    
    public func audioPlayerIsLyricsVisible(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            completion(self?.audioDisplayView?.isLyricsVisible ?? false)
        }
    }
}

// MARK: - Private (AudioDisplayView)

private extension AudioDisplayViewPresenter {
    func replaceDisplayView(audioPlayerDisplayTemplate: AudioPlayerDisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        guard let audioDisplayView = self.audioDisplayView else {
            completion(nil)
            return
        }
        audioDisplayView.displayPayload = audioPlayerDisplayTemplate.payload
        completion(audioDisplayView)
    }
    
    func addDisplayAudioPlayerView(audioPlayerDisplayTemplate: AudioPlayerDisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        if let audioDisplayView = self.audioDisplayView,
           targetView?.subviews.contains(audioDisplayView) == true,
           let audioDisplayViewType = AudioDisplayView.audioPlayerViewType(audioPlayerDisplayTemplate: audioPlayerDisplayTemplate),
           audioDisplayView.isKind(of: audioDisplayViewType) == true {
            replaceDisplayView(audioPlayerDisplayTemplate: audioPlayerDisplayTemplate, completion: completion)
            return
        }
        audioDisplayView?.removeFromSuperview()
        guard let targetView = targetView,
              let audioDisplayView = AudioDisplayView.makeDisplayAudioPlayerView(audioPlayerDisplayTemplate: audioPlayerDisplayTemplate, frame: targetView.frame) else {
            completion(nil)
            return
        }
        audioDisplayView.delegate = self
        audioDisplayView.displayPayload = audioPlayerDisplayTemplate.payload
        
        audioDisplayView.alpha = 0
        if let voiceChrome = targetView.subviews.first(where: { $0.isKind(of: NuguVoiceChrome.self) }) {
            targetView.insertSubview(audioDisplayView, belowSubview: voiceChrome)
        } else {
            targetView.addSubview(audioDisplayView)
        }
        completion(audioDisplayView)
        
        UIView.animate(withDuration: 0.3, animations: {
            audioDisplayView.alpha = 1.0
        }, completion: { [weak self] (_) in
            self?.audioDisplayView = audioDisplayView
        })
    }
    
    func dismissDisplayAudioPlayerView() {
        guard let audioDisplayView = audioDisplayView else { return }
        UIView.animate(
            withDuration: 0.3,
            animations: {
                audioDisplayView.alpha = 0
            },
            completion: { _ in
                audioDisplayView.removeFromSuperview()
            }
        )
    }
}

// MARK: - AudioDisplayViewDelegate

extension AudioDisplayViewPresenter: AudioDisplayViewDelegate {
    public func onCloseButtonClick() {
        nuguClient?.audioPlayerAgent.stop()
    }
    
    public func onUserInteraction() {
        nuguClient?.audioPlayerAgent.notifyUserInteraction()
    }
    
    public func onNuguButtonClick() {
        delegate?.onAudioDisplayViewNuguButtonClick()
    }
    
    public func onChipsSelect(selectedChips: NuguChipsButton.NuguChipsButtonType?) {
        delegate?.onAudioDisplayViewChipsSelect(selectedChips: selectedChips)
    }
    
    public func onPreviousButtonClick() {
        nuguClient?.audioPlayerAgent.prev()
    }
    
    public func onPlayButtonClick() {
        nuguClient?.audioPlayerAgent.play()
    }
    
    public func onPauseButtonClick() {
        nuguClient?.audioPlayerAgent.pause()
    }
    
    public func onNextButtonClick() {
        nuguClient?.audioPlayerAgent.next()
    }
    
    public func onFavoriteButtonClick(current: Bool) {
        nuguClient?.audioPlayerAgent.requestFavoriteCommand(current: current)
    }
    
    public func onRepeatButtonDidClick(currentMode: AudioPlayerDisplayRepeat) {
        nuguClient?.audioPlayerAgent.requestRepeatCommand(currentMode: currentMode)
    }
    
    public func onShuffleButtonDidClick(current: Bool) {
        nuguClient?.audioPlayerAgent.requestShuffleCommand(current: current)
    }
    
    public func requestAudioPlayerIsPlaying() -> Bool? {
        return nuguClient?.audioPlayerAgent.isPlaying
    }
    
    public func requestOffset() -> Int? {
        return nuguClient?.audioPlayerAgent.offset
    }
    
    public func requestDuration() -> Int? {
        return nuguClient?.audioPlayerAgent.duration
    }
}
