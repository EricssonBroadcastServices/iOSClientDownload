//
//  AVAssetTrack+Extensions.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-11-10.
//  Copyright © 2017 emp. All rights reserved.
//

import AVFoundation

extension AVAssetTrack {
    var estimatedSize: Int64 {
        let duration = CMTimeGetSeconds(timeRange.duration)
        let bytesPerSec = Float64(estimatedDataRate / 8) // Convert bps to bytesPerSec
        print("estimatedSize",duration,bytesPerSec,Int64(bytesPerSec * duration))
        return Int64(bytesPerSec * duration)
    }
}
