//
//  StringExtensions.swift
//  SubsonicSwift
//
//  Created by Matt Thomas on 6/18/14.
//  Copyright (c) 2014 Matt Thomas. All rights reserved.
//

import Foundation

extension String {
    var percentEncodedAll: String {
    let allowedCharacters = NSCharacterSet(charactersInString:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")
        return self.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
    }
}
