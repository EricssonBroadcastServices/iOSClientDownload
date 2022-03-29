//
//  FileManager+Extensions.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-10-02.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
public extension FileManager {
    
    /// This method calculates the accumulated size of a directory on the volume in bytes.
    ///
    /// As there's no simple way to get this information from the file system it has to crawl the entire hierarchy,
    /// accumulating the overall sum on the way. The resulting value is roughly equivalent with the amount of bytes
    /// that would become available on the volume if the directory would be deleted.
    ///
    /// - note: There are a couple of oddities that are not taken into account (like symbolic links, meta data of
    /// directories, hard links, ...).
    
    public func allocatedSizeOfDirectory(atUrl url: URL) throws -> UInt64 {
        
        // We'll sum up content size here:
        var accumulatedSize: UInt64 = 0
        
        // prefetching some properties during traversal will speed up things a bit.
        
        let prefetchedProperties = [
            URLResourceKey.isRegularFileKey
            , URLResourceKey.fileAllocatedSizeKey
            , URLResourceKey.totalFileAllocatedSizeKey
        ]
        
        // The error handler simply signals errors to outside code.
        var errorDidOccur: Error?
        let errorHandler: (URL, Error) -> Bool = { _, error in
            errorDidOccur = error
            return false
        }
        
        
        // We have to enumerate all directory contents, including subdirectories.
        let enumerator = self.enumerator(at: url,
                                         includingPropertiesForKeys: prefetchedProperties,
                                         options: FileManager.DirectoryEnumerationOptions.init(rawValue: 0),
                                         errorHandler: errorHandler)
        
        // Start the traversal:
        while let contentItemURL = (enumerator?.nextObject() as? URL)  {
            
            // Bail out on errors from the errorHandler.
            if let error = errorDidOccur { throw error }
            
            // Get the type of this item, making sure we only sum up sizes of regular files.
            let resourceValues = try contentItemURL.resourceValues(forKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
            
            guard resourceValues.isRegularFile ?? false else {
                continue
            }
            
            // To get the file's size we first try the most comprehensive value in terms of what the file may use on disk.
            // This includes metadata, compression (on file system level) and block size.
            var fileSize = resourceValues.fileSize
            
            // In case the value is unavailable we use the fallback value (excluding meta data and compression)
            // This value should always be available.
            fileSize = fileSize ?? resourceValues.totalFileAllocatedSize
            
            // We're good, add up the value.
            accumulatedSize += UInt64(fileSize ?? 0)
        }
        
        // Bail out on errors from the errorHandler.
        if let error = errorDidOccur { throw error }
        
        // We finally got it.
        return accumulatedSize
    }
}
