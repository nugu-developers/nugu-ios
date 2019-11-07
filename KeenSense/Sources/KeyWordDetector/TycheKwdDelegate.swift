//
//  TycheKwdDelegate.swift
//  KeenSense
//
//  Created by childc on 2019/11/11.
//

import Foundation

public protocol TycheKwdDelegate: class {
    /// <#Description#>
    func keyWordDetectorDidDetect()
    /// <#Description#>
    /// - Parameter error: <#error description#>
    func keyWordDetectorDidError(_ error: Error)
    /// <#Description#>
    /// - Parameter state: <#state description#>
    func keyWordDetectorStateDidChange(_ state: KeyWordDetectorState)
}
