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
    public var downloadTask: AVAssetDownloadTask? {
        var task: AVAssetDownloadTask?
        let assetId = self.assetId
        SessionManager
            .default
            .session
            .getAllTasks{ tasks in
                task = tasks
                    .flatMap{ $0 as? AVAssetDownloadTask }
                    .filter{ $0.taskDescription == assetId }
                    .first
                return
        }
        return task
    }
    
    internal init(assetId: String, url: URL) {
        self.assetId = assetId
        self.urlAsset = AVURLAsset(url: url)
    }
    
    internal let assetId: String
    internal let urlAsset: AVURLAsset
    
    public var state: State {
        if #available(iOS 10.0, *) {
            print(urlAsset.url,urlAsset.assetCache?.isPlayableOffline)
            if let assetCache = urlAsset.assetCache, assetCache.isPlayableOffline {
                return .completed
            }
        }
        
        return stateFrom(task: downloadTask)
    }
    
    fileprivate func stateFrom(task: AVAssetDownloadTask?) -> State {
        if let task = task {
            switch task.state {
            case .completed: return .completed
            case .suspended: return .inProgress
            default: return .notFound
            }
        }
        else {
            return .notFound
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
            
            // TODO: Remove LocalMediaRecord
            print("👍 Cleaned up local media after user deleted OfflineMediaAsset")
        }
        catch {
            
        }
    }
}
