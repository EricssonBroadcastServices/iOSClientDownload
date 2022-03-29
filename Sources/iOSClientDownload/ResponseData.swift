//
//  ResponseData.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-10-19.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

public class ResponseData {
    /// destination.bookmarkData()
    /// Bookmark data should be used when persisting this url to disk
    ///
    /// - important: destination URL will be handled diffrently on iOS 9 vs iOS 10. On the later version, storage url for local media is handled and assigned by the system. In iOS 9 this path is supplied by the user.
    internal(set) public var destination: URL?
    
    ///  During the initial asset download, the user’s default media selections—their primary audio and video tracks—are downloaded. If additional media selections such as subtitles, closed captions, or alternative audio tracks are found, the session delegate’s URLSession:assetDownloadTask:didResolveMediaSelection: method is called, indicating that additional media selections exist on the server. To download additional media selections, save a reference to this resolved AVMediaSelection object so you can create subsequent download tasks to be executed serially.
    internal(set) public var resolvedMediaSelection: AVMediaSelection?
    
    public init(destination: URL? = nil, resolvedMediaSelection: AVMediaSelection? = nil) {
        self.destination = destination
        self.resolvedMediaSelection = resolvedMediaSelection
    }
}
