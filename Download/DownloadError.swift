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
    
    case storageUrlNotFound
    case completedWithError(error: Error)
    case failedToDeleteMedia(error: Error)
    case canceledTaskFailedToDeleteLocalMedia
    case downloadSessionInvalidated
    
    /// Unable to load a valid `URL` from path.
    case invalidMediaUrl(path: String)
}
