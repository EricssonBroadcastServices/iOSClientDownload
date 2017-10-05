//
//  OfflineMediaAsset.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-10-03.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation


public struct OfflineMediaAsset {
    /// Returns the download task if download is not complete
    public func downloadTask(callback: @escaping (AVAssetDownloadTask?) -> Void) {
        SessionManager
            .default
            .task(assetId: self.assetId,
                  callback: callback)
    }
    
    internal init(assetId: String, url: URL) {
        self.assetId = assetId
        self.urlAsset = AVURLAsset(url: url)
    }
    
    internal let assetId: String
    internal let urlAsset: AVURLAsset
    
    public func state(callback: @escaping (State) -> Void) {
        if #available(iOS 10.0, *) {
            print("PlayableOffline: ",urlAsset.url,urlAsset.assetCache?.isPlayableOffline)
            if let assetCache = urlAsset.assetCache, assetCache.isPlayableOffline {
                callback(.completed)
                return
            }
        }
        
        downloadTask{ task in
            if let task = task {
                switch task.state {
                case .completed: return callback(.completed)
                case .suspended: return callback(.inProgress)
                default: return callback(.notFound)
                }
            }
            else {
                return callback(.notFound)
            }
        }
    }
    
    public enum State {
        case completed
        case inProgress
        case notFound
    }
    
    /// Deletes locally stored asset data
    public func delete() {
        do {
            try FileManager.default.removeItem(at: urlAsset.url)
            
            Downloader.remove(localRecordId: assetId)
            print("👍 Cleaned up local media after user deleted OfflineMediaAsset")
        }
        catch {
            print("🚨 OfflineMediaAsset delete:",error.localizedDescription)
        }
    }
}
