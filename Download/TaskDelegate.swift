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
                print("✅ DownloadTask completed. 🚨 ", TaskError.completedWithoutValidStorageUrl.message)
                downloadTask.eventPublishTransmitter.onError(downloadTask, nil, TaskError.completedWithoutValidStorageUrl)
                return
            }
            
            // Success
            downloadTask.eventPublishTransmitter.onCompleted(downloadTask, location)
        }
    }
    
    private func handleOnCompletion(error: Error, for downloadTask: T) {
        if let nsError = error as? NSError, nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            handleCancellation(task: downloadTask)
        }
        else {
            print("🚨 DownloadTask completed with error:",error.localizedDescription)
            downloadTask.eventPublishTransmitter.onError(downloadTask, downloadTask.responseData.destination, TaskError.completedWithError(error: error))
        }
    }
    
    private func handleCancellation(task: T) {
        guard let destination = task.responseData.destination else {
            print("🚨 DownloadTask cancelled. ⚠️ ", TaskError.noStoragePathOnCancel.message)
            task.eventPublishTransmitter.onError(task, task.responseData.destination, TaskError.noStoragePathOnCancel)
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
    internal func urlSession(_ session: URLSession, assetDownloadTask: AVAggregateAssetDownloadTask, didFinishDownloadingTo location: URL) {
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
    internal func urlSession(_ session: URLSession, assetDownloadTask: AVAggregateAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
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
    internal func urlSession(_ session: URLSession, assetDownloadTask: AVAggregateAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
        guard let downloadTask = downloadTask else { return }
        downloadTask.responseData.resolvedMediaSelection = resolvedMediaSelection
    }
}
