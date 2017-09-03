//
//  File.swift
//  Breadcrumbs
//
//  Created by Borja Arias Drake on 27/08/2017.
//  Copyright © 2017 Borja Arias Drake. All rights reserved.
//

import Foundation
import UIKit

protocol FlickrImageDownloadDelegate: class {
    
    func handleImageDownloaded(withIdentifier identifier: String,  at url: URL)
    
    func failedDownloadingImage(withIdentifier identifier: String)
}


/// This class downloads images from Flickr API. 
/// It uses the default URLSession configuration, that is, not in the background. 
/// This is an intentional decision that aims to save battery. Images will only be loaded on demand, when requested by the UI,
/// becuase my assumption is that during a walk, the user will not take the phone out of the poket that often. So only, those viewed rows
/// will trigger a download.
class FlickrImageDownloadService: NSObject, URLSessionDelegate {
    
    static var imageFilePrefix = "hike_photo_"
    
    fileprivate let apiKey: String
    
    fileprivate var session : URLSession!
    
    weak var downloadDelegate: FlickrImageDownloadDelegate?
    
    init(apiKey: String) {
        self.apiKey = apiKey
        super.init()
        self.session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)

    }
    
    func downloadImage(with imageMetadata: FlickrPhotoMetadata) {
        
        let task = self.session.downloadTask(with: self.imageDownloadRequest(imageMetadata: imageMetadata)) { (destinationURL, response, error) in
            
            if let destURL = destinationURL, error == nil {
                let fileManager = FileManager.default
                let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
                
                if let documentsDirectoryURL = urls.first {
                    let timestamp = Date().timestamp()
                    let urlInDocumentsDirectory = documentsDirectoryURL.appendingPathComponent("\(FlickrImageDownloadService.imageFilePrefix)\(timestamp).jpg")
                    
                    do {
                        try fileManager.copyItem(at: destURL, to: urlInDocumentsDirectory)
                        self.downloadDelegate?.handleImageDownloaded(withIdentifier: imageMetadata.photoId, at: urlInDocumentsDirectory)
                    } catch {
                        // Report error
                        self.downloadDelegate?.failedDownloadingImage(withIdentifier: imageMetadata.photoId)
                    }
                }
            } else {
                // Report error
                self.downloadDelegate?.failedDownloadingImage(withIdentifier: imageMetadata.photoId)
            }
        }
        
        task.resume()
    }
}



// MARK:- Network Request construction

fileprivate extension FlickrImageDownloadService {
    
    func imageDownloadRequest(imageMetadata: FlickrPhotoMetadata) -> URLRequest {
        let url = URL(string: "https://farm\(imageMetadata.farm).staticflickr.com/\(imageMetadata.server)/\(imageMetadata.photoId)_\(imageMetadata.secret)_n.jpg")        
        let request = URLRequest(url: url!)
        return request
    }
}
