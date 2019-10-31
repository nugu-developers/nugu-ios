//
//  MediaPlayable.swift
//  NuguInterface
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
    var offset: Int { get }
    /// <#Description#>
    var duration: Int { get }
    /// <#Description#>
    var isMuted: Bool { get set }
    
    /// For url source
    /// - Parameter url: <#url description#>
    /// - Parameter offset: <#offset description#>
    func setSource(url: String, offset: Int) throws
    
    /// For data stream source
    /// - Parameter data: <#data description#>
    func appendData(_ data: Data) throws
    
    /// For notify data stream ended
    func lastDataAppended() throws
    
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
    func seek(to offset: Int, completion: ((Result<Void, Error>) -> Void)?)
}

public extension MediaPlayable {
    /// <#Description#>
    /// - Parameter url: <#url description#>
    func setSource(url: String) throws {
        try setSource(url: url, offset: 0)
    }
    
    /// <#Description#>
    /// - Parameter offset: <#offset description#>
    func seek(to offset: Int) {
        seek(to: offset, completion: nil)
    }
}
