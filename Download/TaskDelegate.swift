//
//  DownloadTaskDelegate.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

public class TaskDelegate<T: TaskType>: NSObject {
    internal var downloadTask: T?
    
    public init(task: T) {
        downloadTask = task
    }
}

extension TaskDelegate {
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = downloadTask else {
            return
        }
        
        if let error = error {
            // Completed with error
            handleOnCompletion(error: error, for: downloadTask)
        }
        else {
            // Completed with success
            guard let location = downloadTask.responseData.destination else {
                // Error when no storage url is found
                print("✅ DownloadTask completed. 🚨 ", DownloadError.completedWithoutValidStorageUrl.message)
                downloadTask.eventPublishTransmitter.onError(downloadTask, nil, .downloadError(reason: .completedWithoutValidStorageUrl))
                return
            }
            
            // Success
            guard let resolvedMedia = downloadTask.responseData.resolvedMediaSelection else {
                // 1. No more media available. Trigger onCompleted
                print("✅ DownloadTask completed.")
                downloadTask.eventPublishTransmitter.onCompleted(downloadTask, location)
                return
            }
            
            // 2. Ask, by callback, if and which additional AVMediaSelectionOption's should be included
            if let urlAsset = downloadTask.task?.urlAsset, let newSelection = downloadTask.eventPublishTransmitter.onShouldDownloadMediaOption(downloadTask, AdditionalMedia(asset: urlAsset)) {
                
                // 2.1 User indicated additional media is requested
                let currentMediaOption = resolvedMedia.mutableCopy() as! AVMutableMediaSelection
                
                currentMediaOption.select(newSelection.option, in: newSelection.group)
                
                let options = [AVAssetDownloadTaskMediaSelectionKey: currentMediaOption]
                
                downloadTask.createAndConfigureTask(with: options, using: downloadTask.configuration) { [weak self] urlTask, error in
                    guard let updatedTask = self?.downloadTask else { return }
                    guard error == nil else {
                        updatedTask.eventPublishTransmitter.onError(updatedTask, updatedTask.responseData.destination, error!)
                        return
                    }
                    updatedTask.eventPublishTransmitter.onDownloadingMediaOption(updatedTask, newSelection)
                }
                
                downloadTask.resume()
//                onResumed(self)
            }
            else {
                // 2.2 No additional media was requested
                print("✅ DownloadTask completed.")
                downloadTask.eventPublishTransmitter.onCompleted(downloadTask, location)
            }
        }
    }
    
    private func handleOnCompletion(error: Error, for downloadTask: T) {
        if let nsError = error as? NSError, nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            handleCancellation(task: downloadTask)
        }
        else {
            print("🚨 DownloadTask completed with error:",error.localizedDescription)
            downloadTask.eventPublishTransmitter.onError(downloadTask, downloadTask.responseData.destination, .downloadError(reason: .completedWithError(error: error)))
        }
    }
    
    private func handleCancellation(task: T) {
        guard let destination = task.responseData.destination else {
            print("🚨 DownloadTask cancelled. ⚠️ ", DownloadError.noStoragePathOnCancel.message)
            task.eventPublishTransmitter.onError(task, task.responseData.destination, .downloadError(reason: .noStoragePathOnCancel))
            return
        }
        task.responseData.destination = nil
        print("✅ DownloadTask cancelled.",task.configuration.identifier)
        task.eventPublishTransmitter.onCanceled(task, destination)
    }
}

extension TaskDelegate {
    /// NOTE: Will also be called when a partially downloaded asset is cancelled by the user
    /// Also called onError?
    ///
    /// This delegate callback should only be used to save the location URL somewhere in your application. Any additional work should be done in `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
    @available(iOS 10.0, *)
    internal func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        print("didFinishDownloadingTo",location)
        
        if let size = try? Int64(FileManager.default.allocatedSizeOfDirectory(atUrl: location)) {
            let bytes = ByteCountFormatter.string(fromByteCount: size, countStyle: ByteCountFormatter.CountStyle.file)
            print("📥 DownloadTask finished. \(bytes) on disk at \(location)")
        }
        
        guard let downloadTask = downloadTask else { return }
        
        // This is the location to save as bookmark data
        downloadTask.responseData.destination = location
    }
    
    @available(iOS 9.0, *)
    internal func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        guard let downloadTask = downloadTask else { return }
        var percentComplete = 0.0
        
        for range in loadedTimeRanges {
            let loadedTimeRange = range.timeRangeValue
            percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        
        let progress = Progress(current: percentComplete)
        print("📥 DownloadTask progress: \(progress.current*100) %")
        downloadTask.eventPublishTransmitter.onProgress(downloadTask, progress)
    }
    
    @available(iOS 9.0, *)
    internal func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
        guard let downloadTask = downloadTask else { return }
        downloadTask.responseData.resolvedMediaSelection = resolvedMediaSelection
    }
}
