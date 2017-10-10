//
//  DownloadError.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

public enum DownloadError: Error {
    case generalError(error: Error)
    
    case failedToStartTaskWithoutDestination
    case completedWithError(error: Error)
    case completedWithoutValidStorageUrl
    case noStoragePathOnCancel
    case downloadSessionInvalidated
    
    /// Unable to load a valid `URL` from path.
    case invalidMediaUrl(path: String)
    
    case storageUrlNotFound
    
}


extension DownloadError {
    public var localizedDescription: String {
        switch self {
        case .generalError(error: let error): return "General Error: " + error.localizedDescription
        case .failedToStartTaskWithoutDestination: return "Task failed to start. No valid destination supplied"
        case .completedWithError(error: let error): return "Completed with error: " + error.localizedDescription
        case .completedWithoutValidStorageUrl: return "Completed task has to url to downloaded media"
        case .noStoragePathOnCancel: return "Canceled task has no url to downloaded media"
        case .downloadSessionInvalidated: return "URLSession was invalidated"
        case .invalidMediaUrl(path: let path): return "The supplied path does not specify a valid URL: " + path
        case .storageUrlNotFound: return "Bookmarking resume data requires a destination URL"
        }
    }
}

extension DownloadError {
    /// Defines the `domain` specific code for the underlying error.
    public var code: Int {
        switch self {
        case .generalError(error: _): return 101
        case .failedToStartTaskWithoutDestination: return 102
        case .completedWithError(error: _): return 103
        case .completedWithoutValidStorageUrl: return 104
        case .noStoragePathOnCancel: return 105
        case .downloadSessionInvalidated: return 106
        case .invalidMediaUrl(path: _): return 107
        case .storageUrlNotFound: return 108
        }
    }
}

