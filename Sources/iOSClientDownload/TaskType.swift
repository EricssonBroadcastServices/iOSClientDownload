//
//  DownloadTaskType.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-10-19.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

public protocol TaskType: class, EventPublisher {
    var configuration: Configuration { get }
    var responseData: ResponseData { get }
    var sessionManager: SessionManager<Self> { get }
    var delegate: TaskDelegate<Self> { get }
    var fairplayRequester: FairplayRequester? { get }
    var eventPublishTransmitter: EventPublishTransmitter<Self> { get }
    
    var task: AVAggregateAssetDownloadTask? { get }
    
    associatedtype DownloadState
    
    func resume()
    func suspend()
    func cancel()
    
    func use(bitrate: Int64?, presentationSize: CGSize? ) -> Self
    var state: DownloadState { get }
}

extension TaskType {
    
    @discardableResult
    /// The lowest media bitrate greater than or equal to this value will be selected. If no suitable media bitrate is found, the highest media bitrate will be selected. If this option is not specified, the highest media bitrate will be selected for download by default.
    /// - Parameters:
    ///   - bitrate: The bitrate to select, in bps (bits per second)
    ///   - presentationSize: presentationSize : resolution of the stream
    /// - Returns: self
    public func use(bitrate: Int64?, presentationSize: CGSize? ) -> Self {
        configuration.requiredBitrate = bitrate
        configuration.presentationSize = presentationSize
        return self
    }
}

extension TaskType {
    public func createAndConfigureTask(with options: [String: Any]?, using configuration: Configuration, callback: (AVAggregateAssetDownloadTask?, TaskError?) -> Void) {
        guard let url = configuration.url else {
            callback(nil, TaskError.targetUrlNotFound)
            return
        }
  
        var preferredMedia = [AVMediaSelection]()
        
        
        
        let asset = AVURLAsset(url: url)
        asset.resourceLoader.preloadsEligibleContentKeys = true
        
        if configuration.allAudiosSubs == true {
            
            preferredMedia = asset.allMediaSelections
        
        } else {
            
            preferredMedia = asset.allMediaSelections
            
            // preferredMedia = [AVURLAsset(url: url).preferredMediaSelection]
            /* preferredMediaSelection.removeAll()
            if let group = AVURLAsset(url: url).mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {
                if let subtitles = configuration.subtitles {
                    for sub in subtitles {
                        if let subtitle = group.options.first(where: { $0.displayName == sub }) {
                            for media in AVAsset(url: url).allMediaSelections {
                                if let mediaSelection = media.mutableCopy() as? AVMutableMediaSelection {
                                
                                    mediaSelection.select(subtitle, in: group)
                                    
                                    if !preferredMediaSelection.contains(mediaSelection) {
                                        preferredMediaSelection.append(mediaSelection)
                                        
                                       
                                    }
                                    
                                }
                                
                            }
                        }
                    }
                }
            }

            if let group = AVURLAsset(url: url).mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.audible) {
                if let audios = configuration.audios {
                    for audio in audios {
                        // if let audioOption = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: Locale(identifier: audio)).first {
                        if let audioLang = group.options.first(where: { $0.displayName == audio }) {
                            for media in AVAsset(url: url).allMediaSelections {
                                if let mediaSelection = media.mutableCopy() as? AVMutableMediaSelection {
                                    mediaSelection.select(audioLang, in: group)

                                    if !preferredMediaSelection.contains(mediaSelection) {
                                        preferredMediaSelection.append(mediaSelection)
                                    }
                                }

                            }
                        }
                    }
                }
            } */
            
        }
    
        
        // Use aggregateAssetDownloadTask
        guard let task = sessionManager.session.aggregateAssetDownloadTask(with: asset, mediaSelections: preferredMedia, assetTitle: configuration.identifier, assetArtworkData: configuration.artwork, options: options) else {
            callback(nil, TaskError.downloadSessionInvalidated)
            return
        }
        
        task.taskDescription = configuration.identifier
        configureResourceLoader(for: task)

        callback(task,nil)

    }
    
    public func configureResourceLoader(for task: AVAggregateAssetDownloadTask) {
        if fairplayRequester != nil {
            if task.urlAsset.resourceLoader.delegate != nil {
                task.urlAsset.resourceLoader.setDelegate(nil, queue: nil)
            }
            let queue = DispatchQueue(label: configuration.identifier + "-offlineFairplayLoader")
            
            task.urlAsset.resourceLoader.preloadsEligibleContentKeys = true
            task.urlAsset
                .resourceLoader
                .setDelegate(fairplayRequester, queue: queue)
        }
    }
}

extension TaskType {
    public func handle(restoredTask: AVAggregateAssetDownloadTask) {

        switch restoredTask.state {
            
        case .running:
            eventPublishTransmitter.onPrepared(self)
            eventPublishTransmitter.onResumed(self)
        case .suspended:
            eventPublishTransmitter.onPrepared(self)
            eventPublishTransmitter.onSuspended(self)
        case .canceling:
            print("🚨 The restored task might be stuck in .canceling state") // TODO: How do we handle this?
            break
        case .completed:
            if let error = restoredTask.error {
                eventPublishTransmitter.onError(self, responseData.destination, TaskError.completedWithError(error: error))
            }
            else {
                // Handle completion
                if let destination = responseData.destination {
                    eventPublishTransmitter.onCompleted(self, destination)
                }
                else {
                    eventPublishTransmitter.onError(self, responseData.destination, TaskError.completedWithoutValidStorageUrl)
                }
            }
        }
    }
}

extension TaskType {
    public var duration: Int64? {
        guard let cmTime = task?.urlAsset.duration else { return nil }
        guard !cmTime.isIndefinite else { return nil }
        return Int64(cmTime.seconds*1000)
    }
    
    public var estimatedSize: Int64? {
        
        return task?.urlAsset.tracks.reduce(0) { $0 + $1.estimatedSize }
    }
    
    public var estimatedDownloadedSize: Int64? {
        return task?.countOfBytesReceived
        //        let values = task?.loadedTimeRanges.map{ $0.timeRangeValue }
        //
        //        guard let loadedTimeRanges = values else { return nil }
        //        return task?
        //            .urlAsset
        //            .tracks
        //            .filter{ loadedTimeRanges.contains($0.timeRange) }
        //            .reduce(0) { $0 + $1.estimatedSize }
    }
}
