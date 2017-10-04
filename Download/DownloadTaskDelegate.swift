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
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = downloadTask else { return }
        
        if let error = error {
            // Completed with error
            handleOnCompletion(error: error, for: downloadTask)
        }
        else {
            // Completed with success
            guard let location = downloadTask.configuration.destination else {
                // Error when no storage url is found
                downloadTask.onError(downloadTask, .bookmark(reason: .storageUrlNotFound))
                return
            }
            
            // Store the bookmark data
            saveBookmark(assetId: downloadTask.configuration.assetId, url: location) { bookmarkError in
                if let bookmarkError = bookmarkError {
                    downloadTask.onError(downloadTask, bookmarkError)
                }
                else {
                    // Success
                    guard let resolvedMedia = downloadTask.resolvedMediaSelection else {
                        // 1. No more media available. Trigger onCompleted
                        downloadTask.onCompleted(downloadTask, location)
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
                        downloadTask.onCompleted(downloadTask, location)
                    }
                }
            }
        }
    }
    
    private func handleOnCompletion(error: Error, for downloadTask: DownloadTask) {
        if let nsError = error as? NSError, nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            handleCancellation(task: downloadTask)
        }
        else {
            guard let destination = downloadTask.configuration.destination else {
                downloadTask.onError(downloadTask, .bookmark(reason: .storageUrlNotFound))
                return
            }
            saveBookmark(assetId: downloadTask.configuration.assetId, url: destination) { bookmarkError in
                // We purposefully ignore bookmark related errors here as the onCompletionError takes precedence. TODO: Is this really wise?
                if let bookmarkError = bookmarkError {
                    print("🚨 DownloadTask completed with error. ⚠️ Unable to store bookmark data: \(bookmarkError)")
                }
                else {
                    print("🚨 DownloadTask completed with error. 💾 Bookmark data stored.")
                }
                
                downloadTask.onError(downloadTask, .completedWithError(error: error))
            }
        }
    }
    
    private func handleCancellation(task: DownloadTask) {
        guard let destination = task.configuration.destination else {
            task.onError(task, .bookmark(reason: .storageUrlNotFound))
            return
        }
        
        if task.isResumable {
            // Keep media and make a bookmark
            saveBookmark(assetId: task.configuration.assetId, url: destination) { error in
                if let error = error {
                    print("🚨 DownloadTask cancelled. ⚠️ Unable to store bookmark data.")
                    task.onError(task, error)
                }
                else {
                    print("✅ DownloadTask cancelled. 💾 Bookmark data stored.")
                    task.onCanceled(task)
                }
            }
        }
        else {
            // Remove local media
            do {
                try FileManager.default.removeItem(at: destination)
                Downloader.remove(localRecordId: task.configuration.assetId)
                
                task.configuration.destination = nil
                print("✅ DownloadTask cancelled. 👍 Cleaned up local media.")
                task.onCanceled(task)
            }
            catch {
                print("🚨 DownloadTask cancelled. ⚠️ Failed to clean local media after user cancelled download:",error.localizedDescription)
                task.onError(task, .failedToDeleteMedia(error: error))
            }

        }
    }
    
    private func saveBookmark(assetId: String, url destination: URL, callback: (DownloadError?) -> Void) {
        do {
            let bookmark = try destination.bookmarkData()
            let mediaRecord = LocalMediaRecord(urlBookmark: bookmark, assetId: assetId)
            Downloader.save(localRecord: mediaRecord)
            callback(nil)
        }
        catch {
            callback(.bookmark(reason: .failedToProduceBookmark(error: error)))
        }
    }
}

extension DownloadTaskDelegate {
    /// NOTE: Will also be called when a partially downloaded asset is cancelled by the user
    /// Also called onError?
    ///
    /// This delegate callback should only be used to save the location URL somewhere in your application. Any additional work should be done in `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
    @available(iOS 10.0, *)
    internal func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        print("didFinishDownloadingTo",location)
        
        guard let downloadTask = downloadTask else { return }
        
        if let size = try? Int64(FileManager.default.allocatedSizeOfDirectory(atUrl: location)) {
            let bytes = ByteCountFormatter.string(fromByteCount: size, countStyle: ByteCountFormatter.CountStyle.file)
            print("📥 DownloadTask finished. \(bytes) on disk")
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

