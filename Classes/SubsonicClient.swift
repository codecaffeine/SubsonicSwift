//
//  SubsonicClient.swift
//  SubsonicSwift
//
//  Created by Matt Thomas on 6/4/14.
//  Copyright (c) 2014 Matt Thomas. All rights reserved.
//

import Cocoa

struct Artist {
    let id: Int
    let name: String
    let covertArtRef: String
    let albumCount: Int
}

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
    let baseURL: NSURLComponents
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

    init(appName: String, baseURL: String, sessionConfig: NSURLSessionConfiguration) {
        self.appName = appName
        self.baseURL = NSURLComponents(string: baseURL)
        self.baseURL.path = "/rest"
        self.sessionConfig = sessionConfig
        super.init()
        self.baseURL.query = urlParams
    }

    convenience init(appName: String, baseURL: String, username: String, password: String) {
        let cred = NSURLCredential(user: username,
            password: password,
            persistence: NSURLCredentialPersistence.ForSession)
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.HTTPAdditionalHeaders = cred.basicAuthentication
        self.init(appName: appName, baseURL: baseURL, sessionConfig: sessionConfig)
    }

    func ping(completion: ((NSData!, NSURLResponse!, NSError!) -> Void)!) -> () {
        let pingURL: NSURLComponents = baseURL.copy() as NSURLComponents
        pingURL.path = pingURL.path + "/ping.view"
        println("pingURL.URL: \(pingURL.URL)")
        let task = session.dataTaskWithURL(pingURL.URL) {
            data, response, error in
            completion(data, response, error)
        }
        task.resume()
    }

    func artists(completion: ((NSData!, NSURLResponse!, NSError!) -> Void)!) -> () {
        let urlComponents: NSURLComponents = baseURL.copy() as NSURLComponents
        urlComponents.path = urlComponents.path + "/getArtists.view"
        println("url: \(urlComponents.URL)")
        let task = session.dataTaskWithURL(urlComponents.URL) {
            data, response, error in
            completion(data, response, error)
        }
        task.resume()
    }

    // NSURLSessionDelegate
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
