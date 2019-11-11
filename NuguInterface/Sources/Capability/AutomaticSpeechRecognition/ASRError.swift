//
//  ASRError.swift
//  NuguInterface
//
//  Created by MinChul Lee on 2019/09/30.
//  Copyright © 2019 SKTelecom. All rights reserved.
//

import Foundation

/// <#Description#>
public enum ASRError {
    /// 10초(default) 이내 음성 인결 결과 수신 실패.
    case responseTimeout
    /// Recognize event 시작 후 10초(default) 동안 사용자가 발화하지 않음.
    case listeningTimeout
    /// 음성 인식 시작 실패
    case listenFailed
    /// 음성 인식 실패
    case recognizeFailed
}
