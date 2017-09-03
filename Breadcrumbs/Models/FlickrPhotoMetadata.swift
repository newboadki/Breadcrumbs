//
//  File.swift
//  Breadcrumbs
//
//  Created by Borja Arias Drake on 27/08/2017.
//  Copyright © 2017 Borja Arias Drake. All rights reserved.
//

import Foundation


class FlickrPhotoMetadata {
    
    var photoId: String
    
    var server: String
    
    var farm: Int
    
    var secret: String
    
    /// A URL to the place in disk where the image is. Nil if it hasn't been downloaded yet.
    var localStorageURL: URL?
    
    init(photoId: String, server: String, secret: String, farm: Int) {
        self.photoId = photoId
        self.server = server
        self.secret = secret
        self.farm = farm
    }
}
