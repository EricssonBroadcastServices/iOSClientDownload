//
//  AnalyticsConnectorType.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-11-08.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

public protocol AnalyticsConnectorType {
    associatedtype DownloadTask: TaskType
    
    func downloadPausedEvent(callback: @escaping (DownloadTask) -> Void)
    func downloadResumedEvent(callback: @escaping (DownloadTask) -> Void)
    func downloadCancelledEvent(callback: @escaping (DownloadTask) -> Void)
    func downloadStoppedEvent(callback: @escaping (DownloadTask) -> Void)
    func downloadCompletedEvent(callback: @escaping (DownloadTask) -> Void)
    func downloadErrorEvent(callback: @escaping (DownloadTask, DownloadTask.DownloadEventError) -> Void)
}
