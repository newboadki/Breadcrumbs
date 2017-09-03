//
//  Date+Extension.swift
//  Breadcrumbs
//
//  Created by Borja Arias Drake on 28/08/2017.
//  Copyright © 2017 Borja Arias Drake. All rights reserved.
//

import Foundation

extension Date {
    
    /// Timestamp in miliseconds, for example: 201708281905067
    ///
    /// - Returns: A string representing a timestamp of the receiver's date in miliseconds
    func timestamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
        return dateFormatter.string(from: self)
    }
}
