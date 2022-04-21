//
//  AudioDisplayViewPresenterOptions.swift
//  
//
//  Created by childc on 2022/01/28.
//

import Foundation

public struct AudioDisplayViewPresenterOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let nuguButtons = AudioDisplayViewPresenterOptions(rawValue: 1 << 0)
    public static let barMode  = AudioDisplayViewPresenterOptions(rawValue: 1 << 1)
    public static let nowPlayingInfoCenter   = AudioDisplayViewPresenterOptions(rawValue: 1 << 2)
    
    public static let all: AudioDisplayViewPresenterOptions = [.nuguButtons, .barMode, .nowPlayingInfoCenter]
}
