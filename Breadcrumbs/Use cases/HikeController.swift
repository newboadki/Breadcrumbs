//
//  HikeController.swift
//  Breadcrumbs
//
//  Created by Borja Arias Drake on 27/08/2017.
//  Copyright © 2017 Borja Arias Drake. All rights reserved.
//

import Foundation
import UIKit


/// This class encapsulates the logic for the only use case this application has.
/// Therefore, it coordinates the functioning of all other components.
///  - When the user interface requests an image, it asks the storage coordinator for it. If cached, it will be returned.
///  - If not cached already, then it will ask the metadata service to fetch info about the image.
///  - Finally the user interface will be notified there are updates, in case the app is running in the foreground.
class HikeController: LocationManagerDelegate, FlickrMetadataServiceDelegate, FlickrImageDownloadDelegate {
    
    
    /// Component that interfaces with Apple's CoreLocation framework
    var locationManager: LocationManager
    
    /// Component to perform network requests to retrieve Flickr's picture metadata.
    var metadataService: FlickrMetadataService
    
    /// Component to perform network requests to retrieve Flickr's pictures.
    var imageService: FlickrImageDownloadService
    
    /// Component to abstract the persistence requirements of this application
    var storageManager: StorageManager
    
    /// Component to abstract the interaction with the user interface
    weak var viewController: ListOfLocationImagesUserInterface?
    
    
    
    // MARK: Initializers
    
    /// Designated initializer
    ///
    /// - Parameters:
    ///   - locationManager: Component that interfaces with Apple's CoreLocation framework
    ///   - metadataService: Component to perform network requests to retrieve Flickr's picture metadata.
    ///   - imageService: Component to perform network requests to retrieve Flickr's pictures.
    ///   - storageManager: Component to abstract the persistence requirements of this application
    ///   - viewController: Component to abstract the interaction with the user interface
    init(locationManager: LocationManager,
         metadataService: FlickrMetadataService,
         imageService: FlickrImageDownloadService,
         storageManager: StorageManager,
         viewController: ListOfLocationImagesUserInterface) {
        
        self.locationManager = locationManager
        self.metadataService = metadataService
        self.imageService = imageService
        self.storageManager = storageManager
        self.viewController = viewController
    }
    
    
    
    // MARK: Data Source public API
    
    /// The UI will request images on demand, and they'll get notified via delegation when the resources are ready.
    /// If the image is cached, return it inmediately
    /// If we neet to fetch it, schedule the download and return nil. Results will be returned via delegation.
    ///
    /// - Parameter indexPath: indexPath of the requested resource
    /// - Returns: a local url to the resource, nil if the resource is not cached already.
    func fetchImage(atIndexPath indexPath: IndexPath) -> URL? {
        let lastValidIndex = self.storageManager.count() - 1
        let reversedIndexPath = IndexPath(row: lastValidIndex - indexPath.row, section: 0)
        guard let metadata = self.storageManager.metadata(atIndexPath: reversedIndexPath) else {
            return nil
        }

        // Retrieve the image
        if let localURL = metadata.localStorageURL {
            // Already downloaded, let the view know
            return localURL
        } else {
            // Request it, results will be available through delegation. Completion block is an alternative.
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.imageService.downloadImage(with: metadata)
            return nil
        }
    }
    
    /// - Returns: number of pictures that will be displayed
    func count() -> Int {
        return self.storageManager.count()
    }
}




// MARK: - LocationManagerDelegate
extension HikeController {
    
    func positionThresholdMet(atLatitude latitude: Double, andLongitude longitude: Double) {
        
        // Fetch Metadata for image at location.
        self.metadataService.downloadImage(withLatitude: latitude, andLongitude: longitude)
    }
    
    func handle(error: LocationRetrievalError) {
        
    }
}



// MARK: - FlickrMetadataServiceDelegate

extension HikeController {
    
    func handleDownloadResults(imageMetadata: FlickrPhotoMetadata) {
        // Store metadata
        self.storageManager.store(metadata: imageMetadata)
        
        self.viewController?.reload()
    }
}



// MARK: - FlickrImageDownloadDelegate

extension HikeController {
    
    func handleImageDownloaded(withIdentifier identifier: String,  at url: URL) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        // Index the image
        self.storageManager.associate(imageAtURL: url, forIdentifier: identifier)
        
        // Get indexPath
        let row = self.storageManager.indexPath(for: identifier)
        
        if let r = row {
            // Let the view know
            self.viewController?.handle(url: url, for: IndexPath(row: r, section: 0))
        }
    }
    
    func failedDownloadingImage(withIdentifier identifier: String) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        // Simplification so that there are no empty cells, no retrials.
        self.storageManager.deleteMetadata(withIdentifier: identifier)
    }
}
