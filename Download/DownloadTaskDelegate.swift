//
//  DownloadTaskDelegate.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

internal class DownloadTaskDelegate: NSObject {
    internal var downloadTask: DownloadTask?
    
    internal init(task: DownloadTask) {
        downloadTask = task
    }
}

extension DownloadTaskDelegate {
    fileprivate func storeLocalMediaRecord(task: DownloadTask, error: Error?) {
        guard let destination = task.configuration.destination else { return }
        
        do {
            let bookmark = try destination.bookmarkData()
            let mediaRecord = LocalMediaRecord(urlBookmark: bookmark, assetId: task.configuration.name)
            
            if let error = error {
                if let nsError = error as? NSError {
                    switch (nsError.domain, nsError.code) {
                    case (NSURLErrorDomain, NSURLErrorCancelled):
                        // We should not store a record for deletion events
                        return
                    default:
                        Downloader.save(localRecord: mediaRecord)
                    }
                }
                else {
                    Downloader.save(localRecord: mediaRecord)
                }
            }
            else {
                Downloader.save(localRecord: mediaRecord)
            }
        }
        catch {
            
        }
        
    }
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        guard let downloadTask = downloadTask else { return }
        
        storeLocalMediaRecord(task: downloadTask, error: error)
        
        if let error = error {
            // Error
            if let nsError = error as? NSError {
                switch (nsError.domain, nsError.code) {
                case (NSURLErrorDomain, NSURLErrorCancelled):
                    // This task was canceled by user. URL was saved from
                    guard let location = downloadTask.configuration.destination else {
                        print("🚨 Failed to delete local media after user cancelled download: destination url not found")
                        downloadTask.onError(downloadTask, .failedToDeleteMediaUrlNotFound)
                        return
                    }
                    
                    do {
                        try FileManager.default.removeItem(at: location)
                        downloadTask.configuration.destination = nil
                        print("👍 Cleaned up local media after user cancellation of download")
                        downloadTask.onCanceled(downloadTask)
                    }
                    catch {
                        print("🚨 Failed to clean local media after user cancelled download:",error.localizedDescription)
                        downloadTask.onError(downloadTask, .failedToDeleteMedia(error: error))
                    }
                default:
                    downloadTask.onError(downloadTask, .completedWithError(error: error))
                }
            }
            else {
                downloadTask.onError(downloadTask, .completedWithError(error: error))
            }
        }
        else {
            // Success
            guard let resolvedMedia = downloadTask.resolvedMediaSelection else {
                // 1. No more media available. Trigger onCompleted
                finalize(downloadTask: downloadTask)
                return
            }
            
            // 2. Ask, by callback, if and which additional AVMediaSelectionOption's should be included
            if let newSelection = downloadTask.onShouldDownloadMediaOption(downloadTask, AdditionalMedia(asset: downloadTask.urlAsset)) {
                // 2.1 User indicated additional media is requested
                let currentMediaOption = resolvedMedia.mutableCopy() as! AVMutableMediaSelection
                
                currentMediaOption.select(newSelection.option, in: newSelection.group)
                
                let options = [AVAssetDownloadTaskMediaSelectionKey: currentMediaOption]
                
                downloadTask.startTask(with: options) { [weak self] error in
                    guard let updatedTask = self?.downloadTask else { return }
                    guard error == nil else {
                        updatedTask.onError(updatedTask, error!)
                        return
                    }
                    updatedTask.onDownloadingMediaOption(updatedTask, newSelection)
                }
            }
            else {
                // 2.2 No additional media was requested
                finalize(downloadTask: downloadTask)
            }
        }
        
    }
    
    private func finalize(downloadTask: DownloadTask) {
        guard let location = downloadTask.configuration.destination else {
            // 3. Error when no storage url is found
            downloadTask.onError(downloadTask, .storageUrlNotFound)
            return
        }
        
        downloadTask.onCompleted(downloadTask, location)
    }
}

extension DownloadTaskDelegate {
    /// NOTE: Will also be called when a partially downloaded asset is cancelled by the user
    /// Also called onError?
    ///
    /// This delegate callback should only be used to save the location URL somewhere in your application. Any additional work should be done in `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
    @available(iOS 10.0, *)
    internal func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        guard let downloadTask = downloadTask else { return }
        
        do {
            let size = try Int64(FileManager.default.allocatedSizeOfDirectory(atUrl: location))
            let bytes = ByteCountFormatter.string(fromByteCount: size, countStyle: ByteCountFormatter.CountStyle.file)
            print("TOTAL SIZE:",bytes)
        }
        catch {
        }

        // This is the location to save as bookmark data
        downloadTask.configuration.destination = location
    }
    
    @available(iOS 9.0, *)
    internal func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        guard let downloadTask = downloadTask else { return }
        var percentComplete = 0.0
        
        for range in loadedTimeRanges {
            let loadedTimeRange = range.timeRangeValue
            percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        
//        let currentSize = currentlyDownloadedSize()
//        let totalSize = currentSize > 0 ? (percentComplete > 0 ? Int64(Double(currentSize) / percentComplete) : 0) : currentSize
        let progress = DownloadTask.Progress(current: percentComplete)
        downloadTask.onProgress(downloadTask, progress)
    }
    
    @available(iOS 9.0, *)
    internal func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
        guard let downloadTask = downloadTask else { return }
        downloadTask.resolvedMediaSelection = resolvedMediaSelection
    }
}

//extension DownloadTaskDelegate {
//    fileprivate func currentlyDownloadedSize() -> Int64 {
//        guard let destination = downloadTask?.configuration.destination else { return -1 }
//
//        do {
//            return try Int64(FileManager.default.allocatedSizeOfDirectory(atUrl: destination))
//        }
//        catch {
//            return -1
//        }
//    }
//}

