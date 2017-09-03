//
//  StorageManager.swift
//  Breadcrumbs
//
//  Created by Borja Arias Drake on 27/08/2017.
//  Copyright © 2017 Borja Arias Drake. All rights reserved.
//

import Foundation


/// This class manages the persistence of images. Current implementation uses disk storage
/// Shall we decide to use another tool like CoreData, the rest of the application won't need to change.
class StorageManager {
        
    /// Normally, we would persist it. Assuming here that it will only last during one execution of the app
    private var index: [FlickrPhotoMetadata]
    
    init() {
        self.index = [FlickrPhotoMetadata]()
    }
    
    func count() -> Int {
        return self.index.count
    }
    
    func store(metadata: FlickrPhotoMetadata) {
        if self.indexPath(for: metadata.photoId) == nil {
            self.index.append(metadata)
        }
    }
    
    func associate(imageAtURL url: URL, forIdentifier identifier: String) {
        let results = self.index.filter { (metadata) -> Bool in
            metadata.photoId == identifier
        }
        if let foundObject = results.first {
            foundObject.localStorageURL = url            
        }
    }
    
    func metadata(atIndexPath indexPath: IndexPath) -> FlickrPhotoMetadata? {
        
        guard indexPath.row >= 0 && indexPath.row < self.index.count else {
            return nil
        }
        
        return index[indexPath.row]
    }
    
    func indexPath(for identifier: String) -> Int? {
        let result = self.index.index { (metadata) -> Bool in
            metadata.photoId == identifier
        }
        
        if result != nil {
            return result
        } else {
            return nil
        }
    }
    
    func deleteMetadata(withIdentifier identifier: String) {
        if let indexToRemove = self.indexPath(for: identifier) {
            self.index.remove(at: indexToRemove)
        }
    }
    
    // Simplification: Poor error handing, silently failing.
    func clearDocumentsDirectory(ofFilesWithPrefix prefix: String) {

        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        
        if let documentsDirectoryURL = urls.first {
            if let directoryEntries = try? fileManager.contentsOfDirectory(at: documentsDirectoryURL, includingPropertiesForKeys: [URLResourceKey](), options: .skipsSubdirectoryDescendants) {
                for url in directoryEntries {
                    if url.lastPathComponent.contains(prefix) {
                        try? fileManager.removeItem(at: url)
                    }
                }
            }
        }
    }
}
