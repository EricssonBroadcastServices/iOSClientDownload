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

extension Downloader {
    public static func offline(assetId: String) -> OfflineMediaAsset? {
        return offlineAssets()
            .filter{ $0.assetId == assetId }
            .first
    }
    
    public static func offlineAssets() -> [OfflineMediaAsset] {
        return localMediaLog?.log.flatMap{ resolve(mediaRecord: $0) } ?? []
    }
    
    private static func resolve(mediaRecord: LocalMediaRecord) -> OfflineMediaAsset? {
        
        var bookmarkDataIsStale = false
        do {
            guard let url = try URL(resolvingBookmarkData: mediaRecord.urlBookmark, bookmarkDataIsStale: &bookmarkDataIsStale) else {
                // TODO: Mark this LocalMediaRecord as unavailable, schedule for removal
                return nil
            }
            
            guard !bookmarkDataIsStale else {
                // TODO: Mark bookmark data as stale, schedule removal of LocalMediaRecord
                return nil
            }
            
            return OfflineMediaAsset(assetId: mediaRecord.assetId, url: url)
        }
        catch {
            // TODO: An error occured. Do we schedule removal?
            return nil
        }
    }
    
    internal static var localMediaLog: LocalMediaLog? {
        do {
            let logFile = try logFileURL()
            
            if !FileManager.default.fileExists(atPath: logFile.path) {
                return LocalMediaLog(log: [])
            }
            let data = try Data(contentsOf: logFile)
            
            let localMedia = try JSONDecoder().decode(LocalMediaLog.self, from: data)
            
            localMedia.log.forEach{ print("📎 Local media id: \($0.assetId)") }
            return localMedia
        }
        catch {
            print("localMediaLog failed",error.localizedDescription)
            return nil
        }
    }
    
    /// This method will ensure `LocalMediaLog` has a unique list of downloads with respect to `assetId`
    internal static func save(localRecord: LocalMediaRecord) {
        guard let currentLog = localMediaLog?.log else { return }
        
        // Delte any currently stored OfflineMediaAssets with `localRecord.assetId as they are considered "duplicate"
        var filteredLog = currentLog
            .filter{ record -> Bool in
                if record.assetId == localRecord.assetId {
                    resolve(mediaRecord: record)?.delete()
                    return false
                }
                else {
                    return true
                }
        }
        
        filteredLog.append(localRecord)
        let mediaLog = LocalMediaLog(log: filteredLog)
        save(mediaLog: mediaLog)
    }
    
    private static func save(mediaLog: LocalMediaLog) {
        do {
            let logURL = try baseDirectory()
            
            let data = try JSONEncoder().encode(mediaLog)
            try data.persist(as: logFileName, at: logURL)
        }
        catch {
            print("save(localRecord:) failed",error.localizedDescription)
        }
    }
    
    internal static var logFileName: String {
        return "localMediaLog"
    }
    
    internal static func remove(localRecordId: String) {
        guard let log = localMediaLog?.log else { return }
        
        let newLog = log.filter{ $0.assetId != localRecordId }
        let mediaLog = LocalMediaLog(log: newLog)
        save(mediaLog: mediaLog)
    }
    
    internal static func logFileURL() throws -> URL {
        return try baseDirectory().appendingPathComponent(logFileName)
    }
    
    /// This directory should be reserved for analytics data.
    ///
    /// - returns: `URL` to the base directory
    /// - throws: `FileManager` error
    fileprivate static func baseDirectory() throws -> URL {
        return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("emp")
            .appendingPathComponent("offlineMedia")
    }
}
