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
    var basicAuthenticationHeaders: Dictionary<String, String> {
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
    var urlComponents: NSURLComponents?
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

    init(appName: String, sessionConfig: NSURLSessionConfiguration) {
        self.appName = appName
        self.sessionConfig = sessionConfig
        super.init()
    }

    func authenticate(#baseURL: String, user: String, password: String, completion: ((NSURLCredential!, NSURLResponse!, NSError!) -> Void)) {

        urlComponents = NSURLComponents(string: baseURL)
        if urlComponents {
            urlComponents!.path = "/rest"
            urlComponents!.query = urlParams
        }

        let cred = NSURLCredential(user: user, password: password,
            persistence: NSURLCredentialPersistence.Permanent)
        self.sessionConfig.HTTPAdditionalHeaders = cred.basicAuthenticationHeaders

        ping() {
            data, response, error in

            println("data: \(data)")
            var responseCredential : NSURLCredential?

            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    var jsonErr : NSError?
                    if let responseDict = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(), error: &jsonErr) as? Dictionary<String, Dictionary<String, String>> {
                        if let status = responseDict["subsonic-response"]?["status"] {
                            if status == "ok" {
                                responseCredential = cred
                            }
                        }
                    }
                }
            }

            completion(responseCredential, response, error)
        }
    }

    func ping(completion: ((NSData!, NSURLResponse!, NSError!) -> Void)) {
        if urlComponents {
            let pingComponents: NSURLComponents = urlComponents!.copy() as NSURLComponents
            pingComponents.path = pingComponents.path + "/ping.view"
            println("pingURL.URL: \(pingComponents.URL)")
            let task = session.dataTaskWithURL(pingComponents.URL) {
                data, response, error in
                completion(data, response, error)
            }
            task.resume()
        }
    }

    func artists(completion: ((NSData!, NSURLResponse!, NSError!) -> Void)) {
        if urlComponents {
            let artistComponents: NSURLComponents = urlComponents!.copy() as NSURLComponents
            artistComponents.path = artistComponents.path + "/getArtists.view"
            println("get artists: \(artistComponents.URL)")
            let task = session.dataTaskWithURL(artistComponents.URL) {
                data, response, error in
                completion(data, response, error)
            }
            task.resume()
        }
    }

    // NSURLSessionDelegate
    func URLSession(session: NSURLSession!, task: NSURLSessionTask!, willPerformHTTPRedirection response: NSHTTPURLResponse!, newRequest request: NSURLRequest!, completionHandler: ((NSURLRequest!) -> Void)!) {
        var newRequest: NSURLRequest?
        if response {
            var req = request.mutableCopy() as NSMutableURLRequest
            if let additionalHeaders = session.configuration.HTTPAdditionalHeaders {
                additionalHeaders.enumerateKeysAndObjectsUsingBlock() {
                    (key, value, stop) in
                    if let keyString = key as? String {
                        if let valueString = value as? String {
                            req.setValue(valueString, forHTTPHeaderField: keyString)
                        }
                    }
                }

            }
            newRequest = req.copy() as? NSURLRequest
        }
        completionHandler(newRequest)
    }
}
