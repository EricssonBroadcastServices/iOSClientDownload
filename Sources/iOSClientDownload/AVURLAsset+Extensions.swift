//
//  AVURLAsset+Extensions.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

extension AVURLAsset {
    // MARK: Subtitles
    private var subtitleGroup: AVMediaSelectionGroup? {
        return mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible)
    }
    
    var availableSubtitles: [MediaOption] {
        guard let group = subtitleGroup else { return [] }
        return group.options.map{ MediaOption(group: group, option: $0) }
    }
    
    /// TODO: How do we find out the *locally* stored media in iOS 9.0?
    @available(iOS 10.0, *)
    var localSubtitles: [MediaOption] {
        guard let group = subtitleGroup else { return [] }
        return assetCache?.mediaSelectionOptions(in: group).map{ MediaOption(group: group, option: $0) } ?? []
    }
    
    // MARK: Audio
    private var audioGroup: AVMediaSelectionGroup? {
        return mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.audible)
    }
    
    var availableAudio: [MediaOption] {
        guard let group = audioGroup else { return [] }
        return group.options.map{ MediaOption(group: group, option: $0) }
    }
    
    /// TODO: How do we find out the *locally* stored media in iOS 9.0?
    @available(iOS 10.0, *)
    var localAudio: [MediaOption] {
        guard let group = audioGroup else { return [] }
        return assetCache?.mediaSelectionOptions(in: group).map{ MediaOption(group: group, option: $0) } ?? []
    }
    
    // MARK: Video
    private var videoGroup: AVMediaSelectionGroup? {
        return mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.visual)
    }
    
    var availableVideo: [MediaOption] {
        guard let group = videoGroup else { return [] }
        return group.options.map{ MediaOption(group: group, option: $0) }
    }
    
    /// TODO: How do we find out the *locally* stored media in iOS 9.0?
    @available(iOS 10.0, *)
    var localVideo: [MediaOption] {
        guard let group = videoGroup else { return [] }
        return assetCache?.mediaSelectionOptions(in: group).map{ MediaOption(group: group, option: $0) } ?? []
    }
}
