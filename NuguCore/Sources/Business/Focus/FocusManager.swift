//
//  FocusManager.swift
//  NuguCore
//
//  Created by MinChul Lee on 11/04/2019.
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

import Foundation

import NuguInterface

public class FocusManager: FocusManageable {
    public weak var delegate: FocusDelegate?
    
    private let focusDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.focus_manager", qos: .userInitiated)
    
    private var channelInfos = [FocusChannelInfo]()
    
    private var dialogState: DialogState = .idle

    public init() {
        log.info("")
    }

    deinit {
        log.info("")
    }
}

// MARK: - FocusManageable

extension FocusManager {
    public func add(channelDelegate: FocusChannelDelegate) {
        remove(channelDelegate: channelDelegate)
        
        let info = FocusChannelInfo(delegate: channelDelegate, focusState: .nothing)
        channelInfos.append(info)
    }
    
    public func remove(channelDelegate: FocusChannelDelegate) {
        channelInfos.removeAll { (info) -> Bool in
            return info.delegate == nil || info.delegate === channelDelegate
        }
    }
    
    public func requestFocus(channelDelegate: FocusChannelDelegate) {
        guard channelInfos.contains(where: { (info) -> Bool in
            return info.delegate === channelDelegate
        }) == true else {
            log.warning("Channel not registered \(channelDelegate)")
            return
        }
        
        focusDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.delegate?.focusShouldAcquire() == true else {
                log.warning("Focus should not acquire. \(channelDelegate.focusChannelConfiguration())")
                self.set(channelDelegate: channelDelegate, focusState: .nothing)
                return
            }
            
            // 우선순위에 따른 Focus 부여
            if let foregroundChannelDelegate = self.foregroundChannelDelegate {
                if foregroundChannelDelegate === channelDelegate {
                    self.set(channelDelegate: channelDelegate, focusState: .foreground)
                } else if channelDelegate.focusChannelConfiguration().priority >= foregroundChannelDelegate.focusChannelConfiguration().priority {
                    self.set(channelDelegate: foregroundChannelDelegate, focusState: .background)
                    self.set(channelDelegate: channelDelegate, focusState: .foreground)
                } else {
                    self.set(channelDelegate: channelDelegate, focusState: .background)
                }
            } else {
                self.set(channelDelegate: channelDelegate, focusState: .foreground)
            }
        }
    }

    public func releaseFocus(channelDelegate: FocusChannelDelegate) {
        guard channelInfos.contains(where: { (info) -> Bool in
            return info.delegate === channelDelegate
        }) == true else {
            log.warning("Channel not registered \(channelDelegate)")
            return
        }
        
        focusDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.set(channelDelegate: channelDelegate, focusState: .nothing)
        }
    }

    public func stopForegroundActivity() {
        focusDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let foregroundChannelDelegate = self.foregroundChannelDelegate else {
                log.warning("Foreground channel not exist")
                return
            }
            
            self.set(channelDelegate: foregroundChannelDelegate, focusState: .nothing)
        }
    }
}

// MARK: - DialogStateDelegate

extension FocusManager: DialogStateDelegate {
    public func dialogStateDidChange(_ state: DialogState) {
        focusDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.dialogState = state
            self.notifyFocusReleased()
        }
    }
}

// MARK: - Private

private extension FocusManager {
    func set(channelDelegate: FocusChannelDelegate, focusState: FocusState) {
        guard let index = channelInfos.firstIndex(where: { (info) -> Bool in
            return info.delegate === channelDelegate
        }) else {
            log.warning("Channel not registered \(channelDelegate)")
            return
        }
        
        channelInfos.remove(at: index)
        channelInfos.append(FocusChannelInfo(delegate: channelDelegate, focusState: focusState))
        
        channelDelegate.focusChannelDidChange(focusState: focusState)
        
        switch focusState {
        case .nothing:
            assignForeground()
            notifyFocusReleased()
        case .foreground, .background:
            break
        }
    }
    
    func assignForeground() {
        /// Background -> Foreground
        focusDispatchQueue.asyncAfter(deadline: .now() + FocusConst.shortLatency) { [weak self] in
            guard let self = self else { return }
            guard
                self.foregroundChannelDelegate == nil,
                let backgroundChannelDelegate = self.backgroundChannelDelegate else {
                    return
            }
            
            self.set(channelDelegate: backgroundChannelDelegate, focusState: .foreground)
        }
    }
    
    func notifyFocusReleased() {
        if self.dialogState == .idle && channelInfos.allSatisfy({ $0.delegate == nil || $0.focusState == .nothing }) {
            delegate?.focusShouldRelease()
        }
    }
    
    var foregroundChannelDelegate: FocusChannelDelegate? {
        return self.channelInfos.first(where: { (info) -> Bool in
            return info.focusState == .foreground
        })?.delegate
    }
    
    var backgroundChannelDelegate: FocusChannelDelegate? {
        return self.channelInfos
            .filter { $0.focusState == .background }
            .compactMap { $0.delegate}
            .sorted { $0.focusChannelConfiguration().priority > $1.focusChannelConfiguration().priority  }
            .first
    }
}
