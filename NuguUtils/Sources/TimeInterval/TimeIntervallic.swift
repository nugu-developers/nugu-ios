//
//  TimeIntervallic.swift
//  NuguUtils
//
//  Created by yonghoonKwon on 2019/11/20.
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
import AVFoundation

// MARK: - TimeIntervallic

/// A type with a time interval representation.
public protocol TimeIntervallic {
    
    /// A number of seconds.
    var seconds: Double { get }
    
    /// A number of milliseconds.
    var milliseconds: Double { get }
}

// MARK: - TimeIntervallic + Optional

public extension TimeIntervallic {
    /// A number of milliseconds.
    var milliseconds: Double {
        return seconds * 1000.0
    }
}

// MARK: - TimeIntervallic + Int

public extension TimeIntervallic {
    /// A number of seconds.
    var truncatedSeconds: Int {
        guard seconds.isNaN == false else { return 0 }
        
        switch seconds {
        case .infinity:
            return Int.max
        case -.infinity:
            return Int.min
        default:
            return Int(seconds)
        }
    }
    
    /// A number of milliseconds.
    var truncatedMilliSeconds: Int {
        let secondToMilliseconds = seconds * 1000.0
        guard secondToMilliseconds.isNaN == false else { return 0 }

        switch secondToMilliseconds {
        case .infinity:
            return Int.max
        case -.infinity:
            return Int.min
        default:
            return Int(secondToMilliseconds)
        }
    }
}

// MARK: - DispatchTimeInterval + TimeIntervallic

extension DispatchTimeInterval: TimeIntervallic {
    public var seconds: Double {
        switch self {
        case .seconds(let seconds):
            return Double(seconds)
        case .milliseconds(let milliseconds):
            return Double(milliseconds) / 1000.0
        case .microseconds(let microseconds):
            return Double(microseconds) / Double(USEC_PER_SEC)
        case .nanoseconds(let nanoseconds):
            return Double(nanoseconds) / Double(NSEC_PER_SEC)
        case .never:
            return 0.0
        @unknown default:
            NSLog("Unknown type")
            return 0.0
        }
    }
}

public extension TimeIntervallic {
    /// <#Description#>
    var dispatchTimeInterval: DispatchTimeInterval {
        return .milliseconds(self.truncatedMilliSeconds)
    }
}

// MARK: - NuguTimeInterval + TimeIntervallic

extension NuguTimeInterval: TimeIntervallic {}

public extension TimeIntervallic {
    /// <#Description#>
    var nuguTimeInterval: NuguTimeInterval {
        return NuguTimeInterval(milliseconds: milliseconds)
    }
}

// MARK: - CMTime + TimeIntervallic

extension CMTime: TimeIntervallic {}

public extension TimeIntervallic {
    /// <#Description#>
    var cmTime: CMTime {
        return CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
}
