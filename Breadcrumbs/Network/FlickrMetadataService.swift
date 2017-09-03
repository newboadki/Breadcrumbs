//
//  FlickrService.swift
//  Breadcrumbs
//
//  Created by Borja Arias Drake on 26/08/2017.
//  Copyright © 2017 Borja Arias Drake. All rights reserved.
//

import UIKit

protocol FlickrMetadataServiceDelegate: class {
    
    func handleDownloadResults(imageMetadata: FlickrPhotoMetadata)
}


/// Class to download information about images using Flickr API.
/// This downloads are performed in the background if necessary to prepare the work for showing images.
/// This metadata objects are kept in memory (not persisted) as a simplification for this exercise.
/// This service does not download the images, only the metadata.
class FlickrMetadataService : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    
    typealias backgroundSessionCompletionBlock = () -> ()
    
    
    static var metadataFilePrefix = "photo_metadata_"
    
    fileprivate let apiKey: String
    
    fileprivate var backgroundSession : URLSession!
    
    public weak var downloadDelegate : FlickrMetadataServiceDelegate?
    
    
    init(apiKey: String) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.background(withIdentifier: "com.ariasdrake.borja.breadcrumbs")
        config.sessionSendsLaunchEvents = true        
        super.init()
        self.backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    public func downloadImage(withLatitude latitude: Double, andLongitude longitude: Double) {
        
        let imageMetadataTask: URLSessionDownloadTask = self.backgroundSession.downloadTask(with: self.imageMetadataRequest(latitude: latitude, longitude: longitude))
        imageMetadataTask.resume()
    }
}



// MARK: - Network Request construction

fileprivate extension FlickrMetadataService {
    func imageMetadataRequest(latitude: Double, longitude: Double) -> URLRequest {
        let url = URL(string: "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(self.apiKey)&accuracy=16&geo_context=2&lat=\(latitude)&lon=\(longitude)&per_page=20&format=json&nojsoncallback=1")
        let request = URLRequest(url: url!)
        return request
    }
}



// MARK: - URLSessionDownloadDelegate

extension FlickrMetadataService {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        
        if let documentsDirectoryURL = urls.first {
            let timestamp = Date().timestamp()
            let urlInDocumentsDirectory = documentsDirectoryURL.appendingPathComponent("\(FlickrMetadataService.metadataFilePrefix)\(timestamp).json")
            
            try? fileManager.removeItem(at: urlInDocumentsDirectory)
            
            do {
                try fileManager.copyItem(at: location, to: urlInDocumentsDirectory)
            } catch {
                // Simplification. If there's an error retrieving the metadata, we silently fail, won't re-attemp
            }
            
            // Simplification. If there's an error retrieving the metadata, we silently fail.
            let dataFromFile: Data? = try? Data(contentsOf: urlInDocumentsDirectory)
            
            if let data = dataFromFile {
                let parser = FlickrPhotoMetadataParser()
                let (metadata, error) = parser.parse(data: data)
                if let imageMetadata = metadata, error == nil {
                    // Store the identifier
                    self.downloadDelegate?.handleDownloadResults(imageMetadata: imageMetadata)
                } else {
                    // Simplification, we do not communicate the failure, the metadata  for the position could not be retrieved, we won't display it and won't retry
                }
                try? fileManager.removeItem(at: urlInDocumentsDirectory)
            }
        }
    }
        
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // I would normally avoid using global references as much as possible. Harder to test, singleton abuse.
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let completionBlock = appDelegate.urlBackgroundSessionCompletionHandler {
            appDelegate.urlBackgroundSessionCompletionHandler = nil
            completionBlock()
        }
    }
    
}
