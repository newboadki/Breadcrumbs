//
//  FlickrPhotoMetadataParser.swift
//  Breadcrumbs
//
//  Created by Borja Arias Drake on 27/08/2017.
//  Copyright © 2017 Borja Arias Drake. All rights reserved.
//

import Foundation

// Assumptions: The structure of the json has to do with the query performed. I am assuming 1 page, 20 photos per page.
class FlickrPhotoMetadataParser {
    
    func parse(data: Data) -> (metadata: FlickrPhotoMetadata?, error: Error?) {
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print(json)
                if let photos = json["photos"] as? Dictionary<String, Any>,
                    let photoDataArray = photos["photo"] as? Array<Any> {
                    
                    let index = Int(arc4random_uniform(UInt32(photoDataArray.count)))
                    if index<photoDataArray.count, let photoData = photoDataArray[index] as? Dictionary<String, Any>,
                        let photoIdentifier = photoData["id"] as? String,
                        let farm = photoData["farm"] as? Int,
                        let server = photoData["server"] as? String,
                        let secret = photoData["secret"] as? String {
                        
                            let metadata = FlickrPhotoMetadata(photoId: photoIdentifier, server: server, secret: secret, farm: farm)
                            return (metadata: metadata, error: nil)
                    } else {
                        return (metadata: nil, error: NSError(domain: "JsonParsing", code: 1, userInfo: nil))
                    }
                } else {
                    return (metadata: nil, error: NSError(domain: "JsonParsing", code: 1, userInfo: nil))
                }
                
            } else {
                return (metadata: nil, error: NSError(domain: "JsonParsing", code: 1, userInfo: nil))
            }
        } catch {
            return (metadata: nil, error: NSError(domain: "JsonParsing", code: 1, userInfo: nil))
        }
    }
}
