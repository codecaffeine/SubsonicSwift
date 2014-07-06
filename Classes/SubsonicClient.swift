//
//  SubsonicClient.swift
//  SubsonicSwift
//
//  Created by Matt Thomas on 6/4/14.
//  Copyright (c) 2014 Matt Thomas. All rights reserved.
//

import Cocoa

protocol JSONSerializable {
    class func fromJSON(json: Dictionary<String, AnyObject>) -> Self?
}

protocol SubsonicResponse: JSONSerializable {
}

struct Artist: JSONSerializable, Printable {
    let id: Int
    let name: String
    let covertArtRef: String
    let albumCount: Int

    var description: String { return name }

    static func fromJSON(json: Dictionary<String, AnyObject>) -> Artist? {
        switch (json["id"], json["name"], json["coverArt"], json["albumCount"]) {
        case(.Some(let idNum as NSNumber),
            .Some(let name as NSString),
            .Some(let covertArtRef as NSString),
            .Some(let albumCountNum as NSNumber)):
            let id = idNum.integerValue
            let albumCount = albumCountNum.integerValue
            return Artist(id: id, name: name, covertArtRef: covertArtRef, albumCount: albumCount)
        default:
            return nil
        }
    }
}

struct Artists: SubsonicResponse {
    var allArtists: Artist[]

    static func fromJSON(json: Dictionary<String, AnyObject>) -> Artists? {
        var artists = Artist[]()
        switch json["index"] {
        case .Some(let indexArray as NSArray):
            if let index = indexArray as? Array<Dictionary<String, AnyObject>> {
                for indexDict in index {
                    switch indexDict["artist"] {
                    case .Some(let artistArray as NSArray):
                        if let artistsArr = artistArray as? Array<Dictionary<String, AnyObject>> {
                            for artistDict in artistsArr {
                                if let artist = Artist.fromJSON(artistDict) {
                                    artists.append(artist)
                                }
                            }
                        }
                    default: ()
                    }
                }
            }
        default: ()
        }
        return Artists(allArtists: artists)
    }
}

struct RequestResponse {
    let status: String
    let version: String
    let response: SubsonicResponse

    static func fromJSON(json: Dictionary<String, AnyObject>) -> RequestResponse? {
        switch json["subsonic-response"] {
        case .Some(let responseDict as NSDictionary):
            var status: String?
            var version: String?
            var subsonicResponse: SubsonicResponse?

            for (key, value : AnyObject) in responseDict as Dictionary<String, AnyObject> {
                switch key {
                case "status":
                    status = value as? String
                case "version":
                    version = value as? String
                case "artists":
                    if let artistsDict = value as? Dictionary<String, AnyObject> {
                        subsonicResponse = Artists.fromJSON(artistsDict)
                    }
                default:
                    println("unhandled key: \(key)")
                }
            }
            switch (status, version, subsonicResponse) {
            case (.Some(_), .Some(_), .Some(_)):
                return RequestResponse(status: status!, version: version!, response: subsonicResponse!)
            default:
                return nil
            }
        default:
            return nil
        }
    }
}


extension NSURLCredential {
    var basicAuthenticationHeaders: Dictionary<String, String> {
        let base64Data = "\(self.user):\(self.password)".dataUsingEncoding(NSUTF8StringEncoding)
        let base64String = base64Data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
        return ["Authorization": "Basic \(base64String)"]
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

    func artists(completion: ((Artist[], NSURLResponse!, NSError!) -> Void)) {
        if urlComponents {
            let artistComponents: NSURLComponents = urlComponents!.copy() as NSURLComponents
            artistComponents.path = artistComponents.path + "/getArtists.view"
            println("get artists: \(artistComponents.URL)")

            let task = session.dataTaskWithURL(artistComponents.URL) {
                data, response, error in

                var artists = Artist[]()
                if data {
                    if let jsonDict = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(), error: nil) as? Dictionary<String, AnyObject> {
                        if let requestResponse = RequestResponse.fromJSON(jsonDict) {
                            if let responseArtists = requestResponse.response as? Artists {
                                artists = responseArtists.allArtists
                            }
                        }
                    }
                }

                completion(artists, response, error)
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
