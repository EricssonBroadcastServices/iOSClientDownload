//
//  Downloader.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-09.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

//public struct OfflineMediaAsset {
//    /// Returns the download task if download is not complete
//    public var downloadTask: DownloadTask? { }
//    
//    /// Deletes locally stored asset data
//    public func delete() { }
//}

public struct Downloader {
    @available(iOS 10.0, *)
    public static func download(mediaLocator: String, named name: String? = nil, artwork artworkData: Data? = nil, using fairplayRequester: DownloadFairplayRequester? = nil) throws -> DownloadTask {
        //"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
        guard let url = URL(string: mediaLocator) else {
            throw DownloadError.invalidMediaUrl(path: mediaLocator)
        }
        return download(mediaLocator: url, named: name, artwork: artworkData, using: fairplayRequester)
    }
    
    @available(iOS 10.0, *)
    public static func download(mediaLocator: URL, named name: String? = nil, artwork artworkData: Data? = nil, using fairplayRequester: DownloadFairplayRequester? = nil) -> DownloadTask {
        return SessionManager
            .default
            .download(mediaLocator: mediaLocator,
                      named: name,
                      artwork: artworkData,
                      using: fairplayRequester)
    }
    
    @available(iOS, introduced: 9.0, deprecated: 10.0)
    public static func download(mediaLocator: String, to destination: URL, using fairplayRequester: DownloadFairplayRequester? = nil) throws -> DownloadTask {
        guard let url = URL(string: mediaLocator) else {
            throw DownloadError.invalidMediaUrl(path: mediaLocator)
        }
        return download(mediaLocator: url, to: destination, using: fairplayRequester)
    }
    
    @available(iOS, introduced: 9.0, deprecated: 10.0)
    public static func download(mediaLocator: URL, to destination: URL, using fairplayRequester: DownloadFairplayRequester? = nil) -> DownloadTask {
        return SessionManager
            .default
            .download(mediaLocator: mediaLocator,
                      to: destination,
                      using: fairplayRequester)
    }
    
//    public static func offline(assetId: String) -> OfflineMediaAsset? { }
}
