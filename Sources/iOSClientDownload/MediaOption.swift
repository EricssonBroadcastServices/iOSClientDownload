//
//  MediaOption.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

public struct MediaOption: Equatable {
    internal let group: AVMediaSelectionGroup
    public let option: AVMediaSelectionOption
    
    public static func == (lhs: MediaOption, rhs: MediaOption) -> Bool {
        return lhs.group == rhs.group && lhs.option == rhs.option
    }
}
