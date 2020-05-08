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

public class FocusManager: FocusManageable {
    public weak var delegate: FocusDelegate?
    
    private let focusDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.focus_manager", qos: .userInitiated)
    
    private var channelInfos = [FocusChannelInfo]()
    
    private var releaseFocusWorkItem: DispatchWorkItem?
    
    public init() {}
}

// MARK: - FocusManageable

extension FocusManager {
    public func add(channelDelegate: FocusChannelDelegate) {
        channelInfos.remove(delegate: channelDelegate)
        
        let info = FocusChannelInfo(delegate: channelDelegate, focusState: .nothing)
        channelInfos.append(info)
    }
    
    public func remove(channelDelegate: FocusChannelDelegate) {
        channelInfos.remove(delegate: channelDelegate)
    }
    
    public func requestFocus(channelDelegate: FocusChannelDelegate) {
        focusDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.channelInfos.object(forDelegate: channelDelegate) != nil else {
                log.warning("\(channelDelegate): Channel not registered")
                return
            }
            guard self.delegate?.focusShouldAcquire() == true else {
                log.warning("Focus should not acquire. \(channelDelegate.focusChannelPriority())")
                self.update(channelDelegate: channelDelegate, focusState: .nothing)
                return
            }
            
            // 우선순위에 따른 Focus 부여
            if let foregroundChannelDelegate = self.foregroundChannelDelegate {
                if foregroundChannelDelegate === channelDelegate {
                    self.update(channelDelegate: channelDelegate, focusState: .foreground)
                } else if channelDelegate.focusChannelPriority().rawValue >= foregroundChannelDelegate.focusChannelPriority().rawValue {
                    self.update(channelDelegate: foregroundChannelDelegate, focusState: .background)
                    self.update(channelDelegate: channelDelegate, focusState: .foreground)
                } else {
                    self.update(channelDelegate: channelDelegate, focusState: .background)
                }
            } else {
                self.update(channelDelegate: channelDelegate, focusState: .foreground)
            }
        }
    }

    public func releaseFocus(channelDelegate: FocusChannelDelegate) {
        focusDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.channelInfos.object(forDelegate: channelDelegate) != nil else {
                log.warning("\(channelDelegate): Channel not registered")
                return
            }
            
            self.update(channelDelegate: channelDelegate, focusState: .nothing)
        }
    }

    public func stopForegroundActivity() {
        focusDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let foregroundChannelDelegate = self.foregroundChannelDelegate else {
                log.info("Foreground channel not exist")
                return
            }
            
            self.update(channelDelegate: foregroundChannelDelegate, focusState: .nothing)
        }
    }
}

// MARK: - Private

private extension FocusManager {
    func update(channelDelegate: FocusChannelDelegate, focusState: FocusState) {
        let info = FocusChannelInfo(delegate: channelDelegate, focusState: focusState)
        guard channelInfos.replace(info: info) != nil else {
            log.warning("\(channelDelegate): Failed set to \(focusState).")
            return
        }
        
        channelDelegate.focusChannelDidChange(focusState: focusState)
        
        switch focusState {
        case .nothing:
            assignForeground()
            notifyReleaseFocusIfNeeded()
        case .foreground, .background:
            releaseFocusWorkItem?.cancel()
        }
    }
    
    func assignForeground() {
        // Background -> Foreground
        focusDispatchQueue.asyncAfter(deadline: .now() + FocusConst.shortLatency) { [weak self] in
            guard let self = self else { return }
            guard self.foregroundChannelDelegate == nil,
                let backgroundChannelDelegate = self.backgroundChannelDelegate else {
                    return
            }
            
            self.update(channelDelegate: backgroundChannelDelegate, focusState: .foreground)
        }
    }
    
    func notifyReleaseFocusIfNeeded() {
        releaseFocusWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.channelInfos.allSatisfy({ $0.delegate == nil || $0.focusState == .nothing }) {
                log.debug("")
                self.delegate?.focusShouldRelease()
            }
        }
        releaseFocusWorkItem = workItem
        focusDispatchQueue.asyncAfter(deadline: .now() + FocusConst.releaseLatency, execute: workItem)
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
            .sorted { $0.focusChannelPriority().rawValue > $1.focusChannelPriority().rawValue }
            .first
    }
}
