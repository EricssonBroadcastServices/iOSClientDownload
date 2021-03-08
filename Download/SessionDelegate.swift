//
//  SessionDelegate.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

public class SessionDelegate<T: TaskType>: NSObject, AVAssetDownloadDelegate {
    
    /// Overrides default behavior for URLSessionDelegate method `urlSessionDidFinishEvents(forBackgroundURLSession:)`.
    internal var sessionDidFinishEventsForBackgroundURLSession: ((URLSession) -> Void)?
    
    internal var sessionDidCompleteWithError: ((URLSession, Error?) -> Void)?
    
    
    private var requests: [Int: T] = [:]
    private let lock = NSLock()

    /// Access the task delegate for the specified asset identifier in a thread-safe manner.
    public subscript(identifier: String) -> T? {
        get {
            lock.lock() ; defer { lock.unlock() }
            requests.forEach{ print("📍 Active DownloadTask \($0.value.configuration.identifier)") }
            return requests.filter{ $0.value.configuration.identifier == identifier }.first?.value
        }
    }
    
    /// Access the task delegate for the specified task in a thread-safe manner.
    public subscript(task: AVAggregateAssetDownloadTask) -> T? {
        get {
            lock.lock() ; defer { lock.unlock() }
            return requests[task.taskIdentifier]
        }
        set {
            lock.lock() ; defer { lock.unlock() }
            requests[task.taskIdentifier] = newValue
        }
    }
    
    // MARK: Lifecycle
    
    /// Initializes the `SessionDelegate` instance.
    ///
    /// - returns: The new `SessionDelegate` instance.
    public override init() {
        super.init()
    }
    
    // MARK: - AVAssetDownloadDelegate
    
    /// NOTE: Will also be called when a partially downloaded asset is cancelled by the user
    /// Also called onError?
    ///
    /// This delegate callback should only be used to save the location URL somewhere in your application. Any additional work should be done in `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
    }
    
    @available(iOS 9.0, *)
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
    }
    
    @available(iOS 9.0, *)
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
    }
    
    // MARK: - URLSessionTaskDelegate
    @available(iOS 11.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Swift.Void) {
        
    }
    
    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Swift.Void) {
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Swift.Void) {
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
    }
    
    public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didCompleteFor resolvedMediaSelection: AVMediaSelection) {
        if let delegate = self[aggregateAssetDownloadTask]?.delegate {
            delegate.urlSession(session, assetDownloadTask: aggregateAssetDownloadTask, didResolve: resolvedMediaSelection)
        }
    }
    
    public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange, for: AVMediaSelection) {
        if let delegate = self[aggregateAssetDownloadTask]?.delegate {
            delegate.urlSession(session, assetDownloadTask: aggregateAssetDownloadTask, didLoad: timeRange, totalTimeRangesLoaded: loadedTimeRanges, timeRangeExpectedToLoad: timeRangeExpectedToLoad)
        }
    }
    
    
    public func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
        if let delegate = self[aggregateAssetDownloadTask]?.delegate {
            delegate.urlSession(session, assetDownloadTask: aggregateAssetDownloadTask, didFinishDownloadingTo: location)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let aggregateAssetDownloadTask = task as? AVAggregateAssetDownloadTask else {
            return
        }
        
        if let delegate = self[aggregateAssetDownloadTask]?.delegate {
            delegate.urlSession(session, task: task, didCompleteWithError: error)
            self[aggregateAssetDownloadTask] = nil
        } else {
            sessionDidCompleteWithError?(session, error)
        }
    }
    
    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        
    }

    
    // MARK: - URLSessionDelegate
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("🚨 URLSession invalidated: \(error?.localizedDescription)")
        // TODO: Invalidated sessions should probably be communicated to the end user somehow. Do we provide an error callback setable from the Manager/Delegate?
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("🛏 URLSession finished background events")
        sessionDidFinishEventsForBackgroundURLSession?(session)
    }
}
