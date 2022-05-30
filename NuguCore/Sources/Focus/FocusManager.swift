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

import NuguUtils

public class FocusManager: FocusManageable {
    public weak var delegate: FocusDelegate?
    
    private let focusDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.focus_manager", qos: .userInitiated)
    private let focusDelegateDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.focus_manager_delegate", qos: .userInitiated)
    
    @Atomic private var channelInfos = [FocusChannelInfo]()
    
    private var releaseFocusWorkItem: DispatchWorkItem?
    
    public init() {}
}

// MARK: - FocusManageable

public extension FocusManager {
    func add(channelDelegate: FocusChannelDelegate) {
        _channelInfos.mutate {
            $0.remove(delegate: channelDelegate)
            
            let info = FocusChannelInfo(delegate: channelDelegate, focusState: .nothing)
            $0.append(info)
        }
    }
    
    func remove(channelDelegate: FocusChannelDelegate) {
        _channelInfos.mutate {
            $0.remove(delegate: channelDelegate)
        }
    }
    
    func prepareFocus(channelDelegate: FocusChannelDelegate) {
        focusDispatchQueue.sync { [weak self] in
            guard let self = self else { return }
            
            self.update(channelDelegate: channelDelegate, focusState: .prepare)
        }
    }
    
    func cancelFocus(channelDelegate: FocusChannelDelegate) {
        focusDispatchQueue.sync { [weak self] in
            guard let self = self else { return }
            guard let info = self.channelInfos.object(forDelegate: channelDelegate),
                  info.focusState == .prepare else { return }
            
            self.update(channelDelegate: channelDelegate, focusState: .nothing)
        }
    }
    
    func requestFocus(channelDelegate: FocusChannelDelegate) {
        focusDispatchQueue.sync { [weak self] in
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
            
            guard self.foregroundChannelDelegate !== channelDelegate else {
                self.update(channelDelegate: channelDelegate, focusState: .foreground)
                return
            }
            
            // Move current foreground channel to background If Its priority is lower than requested.
            if let foregroundChannelDelegate = self.foregroundChannelDelegate,
                channelDelegate.focusChannelPriority().requestPriority >= foregroundChannelDelegate.focusChannelPriority().maintainPriority {
                self.update(channelDelegate: foregroundChannelDelegate, focusState: .background)
            }

            if let prepareChannelDelegate = self.prepareChannelDelegate,
               prepareChannelDelegate !== channelDelegate,
               channelDelegate.focusChannelPriority().requestPriority < prepareChannelDelegate.focusChannelPriority().requestPriority {
                // Prepare channel will request focus in the future.
                self.update(channelDelegate: channelDelegate, focusState: .background)
            } else if let backgroundChannelDelegate = self.backgroundChannelDelegate,
               backgroundChannelDelegate !== channelDelegate,
                channelDelegate.focusChannelPriority().requestPriority < backgroundChannelDelegate.focusChannelPriority().maintainPriority {
                // Assign a higher background channel to the foreground in the future.
                self.update(channelDelegate: channelDelegate, focusState: .background)
            } else if self.foregroundChannelDelegate == nil {
                self.update(channelDelegate: channelDelegate, focusState: .foreground)
            } else {
                self.update(channelDelegate: channelDelegate, focusState: .background)
            }
        }
    }

    func releaseFocus(channelDelegate: FocusChannelDelegate) {
        focusDispatchQueue.sync { [weak self] in
            guard let self = self else { return }
            guard self.channelInfos.object(forDelegate: channelDelegate) != nil else {
                log.warning("\(channelDelegate): Channel not registered")
                return
            }
            
            self.update(channelDelegate: channelDelegate, focusState: .nothing)
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
        
        focusDelegateDispatchQueue.async {
            channelDelegate.focusChannelDidChange(focusState: focusState)
        }
        
        switch focusState {
        case .nothing:
            assignForeground()
            notifyReleaseFocusIfNeeded()
        case .background, .foreground, .prepare:
            releaseFocusWorkItem?.cancel()
        }
    }
    
    func assignForeground() {
        // Assign a higher background channel to the foreground with some delay so that it doesn't acquire the focus temporarily.
        focusDispatchQueue.asyncAfter(deadline: .now() + FocusConst.shortLatency) { [weak self] in
            guard let self = self else { return }
            
            log.debug("foregroundChannelDelegate: \(self.foregroundChannelDelegate.debugDescription), backgroundChannelDelegate: \(self.backgroundChannelDelegate.debugDescription)")
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
            
            log.debug("notifyReleaseFocusIfNeeded, channelInfos: \(self.channelInfos)")
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
            .sorted { $0.focusChannelPriority().maintainPriority > $1.focusChannelPriority().maintainPriority }
            .first
    }
    
    var prepareChannelDelegate: FocusChannelDelegate? {
        return self.channelInfos
            .filter { $0.focusState == .prepare }
            .compactMap { $0.delegate}
            .sorted { $0.focusChannelPriority().requestPriority > $1.focusChannelPriority().requestPriority }
            .first
    }
}
