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
    case failedToDeleteMedia(error: Error)
    case failedToDeleteMediaUrlNotFound
    case downloadSessionInvalidated
    
    /// Unable to load a valid `URL` from path.
    case invalidMediaUrl(path: String)
    
    case bookmark(reason: BookmarkDataFailure)
}

extension DownloadError {
    public enum BookmarkDataFailure {
        case storageUrlNotFound
        case failedToProduceBookmark(error: Error)
    }
}

extension DownloadError {
    public var localizedDescription: String {
        switch self {
        case .generalError(error: let error): return "General Error: " + error.localizedDescription
        case .failedToStartTaskWithoutDestination: return "Task failed to start. No valid destination supplied"
        case .completedWithError(error: let error): return "Completed with error: " + error.localizedDescription
        case .failedToDeleteMedia(error: let error): return "Failed to delete media: " + error.localizedDescription
        case .failedToDeleteMediaUrlNotFound: return "Failed to delete media, URL not found"
        case .downloadSessionInvalidated: return "URLSession was invalidated"
        case .invalidMediaUrl(path: let path): return "The supplied path does not specify a valid URL: " + path
        case .bookmark(reason: let reason): return "Bookmarking: " + reason.localizedDescription
        }
    }
}

extension DownloadError.BookmarkDataFailure {
    public var localizedDescription: String {
        switch self {
        case .storageUrlNotFound: return "Bookmarking resume data requires a destination URL"
        case .failedToProduceBookmark(error: let error): return "Failed to produce a persistable URL for bookmarking: " + error.localizedDescription
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
        case .failedToDeleteMedia(error: _): return 104
        case .failedToDeleteMediaUrlNotFound: return 105
        case .downloadSessionInvalidated: return 106
        case .invalidMediaUrl(path: _): return 107
        case .bookmark(reason: let reason): return reason.code
        }
    }
}

extension DownloadError.BookmarkDataFailure {
    /// Defines the `domain` specific code for the underlying error.
    public var code: Int {
        switch self {
        case .storageUrlNotFound: return 201
        case .failedToProduceBookmark(error: _): return 202
        }
    }
}
