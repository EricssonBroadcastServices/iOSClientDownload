//
//  EventPublishTransmitter.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-10-19.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

public class EventPublishTransmitter<T: EventPublisher> {
    public var onPrepared: (T) -> Void = { _ in }
    public var onSuspended: (T) -> Void = { _ in }
    public var onResumed: (T) -> Void = { _ in }
    public var onCanceled: (T, URL) -> Void = { _,_  in }
    public var onCompleted: (T, URL) -> Void = { _,_  in }
    public var onProgress: (T, Progress) -> Void = { _,_  in }
    public var onError: (T, URL?, Error) -> Void = { _,_,_  in }
    public var onPlaybackReady: (T, URL) -> Void = { _,_  in }
    public var onShouldDownloadMediaOption: ((T, AdditionalMedia) -> MediaOption?) = { _,_  in return nil }
    public var onDownloadingMediaOption: (T, MediaOption) -> Void = { _,_  in }
    
    public init() {
        
    }
}
