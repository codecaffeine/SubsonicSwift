//
//  SubsonicClient.swift
//  SubsonicSwift
//
//  Created by Matt Thomas on 6/4/14.
//  Copyright (c) 2014 Matt Thomas. All rights reserved.
//

import Cocoa

extension String {
    var percentEncodedAll: String {
    let allowedCharacters = NSCharacterSet(charactersInString:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")
        return self.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
    }
}

extension NSURLCredential {
    var basicAuthentication: Dictionary<String, String> {
        let base64Data = "\(self.user):\(self.password)".dataUsingEncoding(NSUTF8StringEncoding)
        let base64String = base64Data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
        return ["Authorization": "Basic \(base64String)"]
    }
}

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

class SubsonicClient: NSObject, NSURLSessionDelegate {
    let baseURL: NSURL
    let version = "1.10.2"
    let format = "json"
    let sessionConfig: NSURLSessionConfiguration
    let appName: String

    @lazy var session: NSURLSession = {
        return NSURLSession(configuration: self.sessionConfig,
            delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }()

    @lazy var urlParams: String = {
        let params = ["v": self.version, "c": self.appName, "f": self.format]
        return params.percentEncodedQueryString
    }()

    init(appName: String, baseURL: NSURL, sessionConfig: NSURLSessionConfiguration) {
        self.appName = appName
        self.baseURL = baseURL
        self.sessionConfig = sessionConfig
        super.init()
    }

    convenience init(appName: String, baseURL:NSURL, username: String, password: String) {
        let cred = NSURLCredential(user: username,
            password: password,
            persistence: NSURLCredentialPersistence.ForSession)
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.HTTPAdditionalHeaders = cred.basicAuthentication
        self.init(appName: appName, baseURL: baseURL, sessionConfig: sessionConfig)
    }

    func ping(completion: ((NSData!, NSURLResponse!, NSError!) -> Void)!) -> () {
        let url = NSURL(string: "\(baseURL.absoluteString)ping.view?\(urlParams)")
        let task = session.dataTaskWithURL(url) {
            (data, response, error) in
            completion(data, response, error)
        }
        task.resume()
    }

    func URLSession(session: NSURLSession!, task: NSURLSessionTask!, willPerformHTTPRedirection response: NSHTTPURLResponse!, newRequest request: NSURLRequest!, completionHandler: ((NSURLRequest!) -> Void)!) {
        var newRequest: NSURLRequest? = nil
        if response {
            var req = request.mutableCopy() as NSMutableURLRequest
            session.configuration.HTTPAdditionalHeaders.enumerateKeysAndObjectsUsingBlock() {
                (key, value, stop) in
                if let keyString = key as? String {
                    if let valueString = value as? String {
                        req.setValue(valueString, forHTTPHeaderField: keyString)
                    }
                }
            }
            newRequest = req.copy() as? NSURLRequest
        }
        completionHandler(newRequest)
    }
}
