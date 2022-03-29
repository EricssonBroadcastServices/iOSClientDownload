//
//  Configuration.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-10-19.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

public class Configuration {
    public let identifier: String
    public var url: URL?
    public let artwork: Data?
    
    public var requiredBitrate: Int64?
    public var subtitles: [String]?
    public var audios: [String]?
    public var allAudiosSubs: Bool = false
    
    public init(identifier: String, url: URL? = nil, artwork: Data? = nil) {
        self.identifier = identifier
        self.url = url
        self.artwork = artwork
    }
}
