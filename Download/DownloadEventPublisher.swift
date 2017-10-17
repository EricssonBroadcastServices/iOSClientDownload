//
//  DownloadEventPublisher.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

public protocol DownloadEventPublisher {
    associatedtype DownloadEventProgress
    associatedtype DownloadEventError
    
    func onPrepared(callback: @escaping (Self) -> Void) -> Self
    
    func onSuspended(callback: @escaping (Self) -> Void) -> Self
    
    func onResumed(callback: @escaping (Self) -> Void) -> Self
    
    func onCanceled(callback: @escaping (Self, URL) -> Void) -> Self
    
    func onCompleted(callback: @escaping (Self, URL) -> Void) -> Self
    
    func onProgress(callback: @escaping (Self, DownloadEventProgress) -> Void) -> Self
    
    func onError(callback: @escaping (Self, URL?, DownloadEventError) -> Void) -> Self
    
    func onPlaybackReady(callback: @escaping (Self, URL) -> Void) -> Self
    
    func onShouldDownloadMediaOption(callback: @escaping (Self, AdditionalMedia) -> MediaOption?) -> Self
    
    func onDownloadingMediaOption(callback: @escaping (Self, MediaOption) -> Void) -> Self
}
