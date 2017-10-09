//
//  Downloader.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-09.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

public struct Downloader {
    @available(iOS 10.0, *)
    public static func download(mediaLocator: String, assetId: String, using fairplayRequester: DownloadFairplayRequester? = nil, artwork artworkData: Data? = nil) throws -> DownloadTask {
        guard let url = URL(string: mediaLocator) else {
            throw DownloadError.invalidMediaUrl(path: mediaLocator)
        }
        return download(mediaLocator: url,
                        assetId: assetId,
                        using: fairplayRequester,
                        artwork: artworkData)
    }
    
    @available(iOS 10.0, *)
    public static func download(mediaLocator: URL, assetId: String, using fairplayRequester: DownloadFairplayRequester? = nil, artwork artworkData: Data? = nil) -> DownloadTask {
        return SessionManager
            .default
            .download(mediaLocator: mediaLocator,
                      assetId: assetId,
                      artwork: artworkData,
                      using: fairplayRequester)
    }
    
    @available(iOS, introduced: 9.0, deprecated: 10.0)
    public static func download(mediaLocator: String, assetId: String, to destination: URL, using fairplayRequester: DownloadFairplayRequester? = nil) throws -> DownloadTask {
        guard let url = URL(string: mediaLocator) else {
            throw DownloadError.invalidMediaUrl(path: mediaLocator)
        }
        return download(mediaLocator: url,
                        assetId: assetId,
                        to: destination,
                        using: fairplayRequester)
    }
    
    @available(iOS, introduced: 9.0, deprecated: 10.0)
    public static func download(mediaLocator: URL, assetId: String, to destination: URL, using fairplayRequester: DownloadFairplayRequester? = nil) -> DownloadTask {
        return SessionManager
            .default
            .download(mediaLocator: mediaLocator,
                      assetId: assetId,
                      to: destination,
                      using: fairplayRequester)
    }
}
