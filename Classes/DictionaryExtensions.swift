//
//  DictionaryExtensions.swift
//  SubsonicSwift
//
//  Created by Matt Thomas on 6/18/14.
//  Copyright (c) 2014 Matt Thomas. All rights reserved.
//

import Foundation

extension Dictionary {
    var percentEncodedQueryString: String {
    var htmlParams = String[]()
        for (key, value) in self {
            if let keyString = key as? String {
                if let valueString = value as? String {
                    htmlParams += "\(keyString.percentEncodedAll)=\(valueString.percentEncodedAll)"
                }
            }
        }
        return NSArray(array:htmlParams).componentsJoinedByString("&")
    }
}
