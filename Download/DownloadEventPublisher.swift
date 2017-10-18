//
//  DownloadEventPublisher.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

public class DownloadEventPublishTransmitter<Task: DownloadEventPublisher> {
    public var onPrepared: (Task) -> Void = { _ in }
    public var onSuspended: (Task) -> Void = { _ in }
    public var onResumed: (Task) -> Void = { _ in }
    public var onCanceled: (Task, URL) -> Void = { _ in }
    public var onCompleted: (Task, URL) -> Void = { _ in }
    public var onProgress: (Task, Progress) -> Void = { _ in }
    public var onError: (Task, URL?, Task.DownloadEventError) -> Void = { _ in }
    public var onPlaybackReady: (Task, URL) -> Void = { _ in }
    public var onShouldDownloadMediaOption: ((Task, AdditionalMedia) -> MediaOption?) = { _ in return nil }
    public var onDownloadingMediaOption: (Task, MediaOption) -> Void = { _ in }
    
    public init() {
        
    }
}



public protocol DownloadEventPublisher {
    associatedtype DownloadEventError: DownloadErrorConvertible
    
    var eventPublishTransmitter: DownloadEventPublishTransmitter<Self> { get }
    
    func onPrepared(callback: @escaping (Self) -> Void) -> Self
    
    func onSuspended(callback: @escaping (Self) -> Void) -> Self
    
    func onResumed(callback: @escaping (Self) -> Void) -> Self
    
    func onCanceled(callback: @escaping (Self, URL) -> Void) -> Self
    
    func onCompleted(callback: @escaping (Self, URL) -> Void) -> Self
    
    func onProgress(callback: @escaping (Self, Progress) -> Void) -> Self
    
    func onError(callback: @escaping (Self, URL?, DownloadEventError) -> Void) -> Self
    
    func onPlaybackReady(callback: @escaping (Self, URL) -> Void) -> Self
    
    func onShouldDownloadMediaOption(callback: @escaping (Self, AdditionalMedia) -> MediaOption?) -> Self
    
    func onDownloadingMediaOption(callback: @escaping (Self, MediaOption) -> Void) -> Self
}

extension DownloadEventPublisher {
    
    @discardableResult
    public func onPrepared(callback: @escaping (Self) -> Void) -> Self {
        eventPublishTransmitter.onPrepared = callback
        return self
    }
    
    @discardableResult
    public func onSuspended(callback: @escaping (Self) -> Void) -> Self {
        eventPublishTransmitter.onSuspended = callback
        return self
    }
    
    @discardableResult
    public func onResumed(callback: @escaping (Self) -> Void) -> Self {
        eventPublishTransmitter.onResumed = callback
        return self
    }
    
    @discardableResult
    public func onCanceled(callback: @escaping (Self, URL) -> Void) -> Self {
        eventPublishTransmitter.onCanceled = callback
        return self
    }
    
    @discardableResult
    public func onCompleted(callback: @escaping (Self, URL) -> Void) -> Self {
        eventPublishTransmitter.onCompleted = callback
        return self
    }
    
    @discardableResult
    public func onProgress(callback: @escaping (Self, Progress) -> Void) -> Self {
        eventPublishTransmitter.onProgress = callback
        return self
    }
    
    @discardableResult
    public func onError(callback: @escaping (Self, URL?, DownloadEventError) -> Void) -> Self {
        eventPublishTransmitter.onError = callback
        return self
    }
    
    @discardableResult
    public func onPlaybackReady(callback: @escaping (Self, URL) -> Void) -> Self {
        eventPublishTransmitter.onPlaybackReady = callback
        return self
    }
    
    @discardableResult
    public func onShouldDownloadMediaOption(callback: @escaping (Self, AdditionalMedia) -> MediaOption?) -> Self {
        eventPublishTransmitter.onShouldDownloadMediaOption = callback
        return self
    }
    
    @discardableResult
    public func onDownloadingMediaOption(callback: @escaping (Self, MediaOption) -> Void) -> Self {
        eventPublishTransmitter.onDownloadingMediaOption = callback
        return self
    }
}
