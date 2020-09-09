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
    
    /// Check for next media selection for download
    /// - Parameters:
    ///   - asset: asset
    ///   - allAudiosSubs: all audios & subtitles
    ///   - audios: audios
    ///   - subtitles: subtitles
    /// - Returns: selection group
    fileprivate func nextMediaSelection(_ asset: AVURLAsset, allAudiosSubs: Bool, audios: [String]?, subtitles: [String]? ) -> (mediaSelectionGroup: AVMediaSelectionGroup?,
        mediaSelectionOption: AVMediaSelectionOption?) {
            
            // If the specified asset has not associated asset cache, return nil tuple
            guard let assetCache = asset.assetCache else {
                return (nil, nil)
            }
            
            // Iterate through audible and legible characteristics to find associated groups for asset
            for characteristic in [AVMediaCharacteristic.audible, AVMediaCharacteristic.legible] {
                
                if let mediaSelectionGroup = asset.mediaSelectionGroup(forMediaCharacteristic: characteristic) {
                    
                    // Determine which offline media selection options exist for this asset
                    let savedOptions = assetCache.mediaSelectionOptions(in: mediaSelectionGroup)
                    
                    // If there are still media options to download...
                    if savedOptions.count < mediaSelectionGroup.options.count {
                        for option in mediaSelectionGroup.options {
                            if !savedOptions.contains(option) {
                                
                                // If all audios & subtitled needs to download
                                if allAudiosSubs {
                                    return (mediaSelectionGroup, option)
                                } else {
                                    
                                    // Start downloading audio
                                    if option.mediaType == .audio {
                                        
                                        // Check if the user has passed any audio
                                        if let audios = audios {
                                            for audio in audios {
                                                
                                                if (audio == option.displayName) {
                                                    print("Found the audio track : \(option.displayName) =>  start downloading ")
                                                    return (mediaSelectionGroup, option)
                                                }
                                            }
                                        }
                                        
                                    }
                                    
                                    // Start downloading subtitles
                                    if option.mediaType == .subtitle {
                                        
                                        if let subtitles = subtitles {
                                            
                                            for sub in subtitles {
                                                if (sub == option.displayName && option.mediaType == .subtitle) {
                                                    print("Found the subtitle track : \(option.displayName) =>  start downloading ")
                                                    return (mediaSelectionGroup, option)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                    }
                }
            }
            
            // At this point all media options have been downloaded.
            return (nil, nil)
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
            guard let resolvedMedia = downloadTask.responseData.resolvedMediaSelection else {
                // 1. No more media available. Trigger onCompleted
                print("✅ DownloadTask completed. No more media available. Trigger onCompleted")
                downloadTask.eventPublishTransmitter.onCompleted(downloadTask, location)
                return
            }
            
            if let urlAsset = downloadTask.task?.urlAsset {
                let mediaSelectionPair = nextMediaSelection(urlAsset, allAudiosSubs: downloadTask.configuration.allAudiosSubs,  audios: downloadTask.configuration.audios, subtitles: downloadTask.configuration.subtitles )
                
                // If an undownloaded media selection option exists in the group...
                if let group = mediaSelectionPair.mediaSelectionGroup,
                    let option = mediaSelectionPair.mediaSelectionOption {
                    
                    // Exit early if no corresponding AVMediaSelection exists for the current task
                    // guard let originalMediaSelection = mediaSelectionMap[task] else { return }
                    
                    // Create a mutable copy and select the media selection option in the media selection group
                    let mediaSelection = resolvedMedia.mutableCopy() as! AVMutableMediaSelection
                    mediaSelection.select(option, in: group)
                    
                    // Create a new download task with this media selection in its options
                    let options = [AVAssetDownloadTaskMediaSelectionKey: mediaSelection]
                    
                    if #available(iOS 10.0, *) {
                        let newAssetDownloadTask = downloadTask.sessionManager.session
                            .makeAssetDownloadTask(asset: urlAsset,
                                                   assetTitle: downloadTask.configuration.identifier,
                                                   assetArtworkData: downloadTask.configuration.artwork,
                                                   options: options)
                        
                        
                        if let task = newAssetDownloadTask {
                            downloadTask.sessionManager.delegate[task] = downloadTask
                        }
                        
                        newAssetDownloadTask?.resume()
                        
                    } else {
                        // Fallback on earlier versions , not supported
                    }
                } else {
                    print("✅ DownloadTask completed")
                    downloadTask.eventPublishTransmitter.onCompleted(downloadTask, location)
                }
            }
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
