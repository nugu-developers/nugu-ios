//
//  MediaPlayable.swift
//  NuguCore
//
//  Created by MinChul Lee on 22/04/2019.
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

/// <#Description#>
public protocol MediaPlayable: class {
    /// <#Description#>
    var delegate: MediaPlayerDelegate? { get set }
    /// <#Description#>
    var offset: TimeIntervallic { get }
    /// <#Description#>
    var duration: TimeIntervallic { get }
    /// <#Description#>
    var isMuted: Bool { get set }
    
    /// <#Description#>
    func play()
    /// <#Description#>
    func stop()
    /// <#Description#>
    func pause()
    /// <#Description#>
    func resume()
    /// <#Description#>
    /// - Parameter offset: <#offset description#>
    /// - Parameter completion: <#completion description#>
    func seek(to offset: TimeIntervallic, completion: ((Result<Void, Error>) -> Void)?)
}

// MARK: - MediaPlayable + Optional

public extension MediaPlayable {
    /// <#Description#>
    /// - Parameter offset: <#offset description#>
    func seek(to offset: TimeIntervallic) {
        seek(to: offset, completion: nil)
    }
}
