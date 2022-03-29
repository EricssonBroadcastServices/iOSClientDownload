//
//  AdditionalMedia.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

public struct AdditionalMedia {
    internal let asset: AVURLAsset
    
    public var subtitles: [MediaOption] {
        if #available(iOS 10.0, *) {
            let local = asset.localSubtitles
            return asset.availableSubtitles.filter{ !local.contains($0) }
        }
        else {
            return asset.availableSubtitles
        }
    }
    
    public var audio: [MediaOption] {
        if #available(iOS 10.0, *) {
            let local = asset.localAudio
            return asset.availableAudio.filter{ !local.contains($0) }
        }
        else {
            return asset.availableAudio
        }
    }
    
    public var video: [MediaOption] {
        if #available(iOS 10.0, *) {
            let local = asset.localVideo
            return asset.availableVideo.filter{ !local.contains($0) }
        }
        else {
            return asset.availableVideo
        }
    }
}
