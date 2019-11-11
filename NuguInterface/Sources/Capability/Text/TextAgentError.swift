//
//  TextAgentError.swift
//  NuguInterface
//
//  Created by MinChul Lee on 2019/10/04.
//

import Foundation

/// An error of text recognition.
public enum TextAgentError: Error {
    /// Text recognition has occured timeout.
    case responseTimeout
}
