//
//  AppDelegate.swift
//  SubsonicSwift
//
//  Created by Matt Thomas on 6/3/14.
//  Copyright (c) 2014 Matt Thomas. All rights reserved.
//

import Cocoa

let ProtectionSpace = "ProtectionSpace"
let AppName = "Subsonic Swift"

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet var window: NSWindow
    let client: SubsonicClient
    var loginViewController: LoginViewController?
    let loginProtectionSpace: NSURLProtectionSpace?

    init() {
        client = SubsonicClient(appName: AppName,
            sessionConfig: NSURLSessionConfiguration.defaultSessionConfiguration())
        super.init()
    }

    func applicationDidFinishLaunching(aNotification: NSNotification?) {

        if let data = NSUserDefaults.standardUserDefaults().objectForKey(ProtectionSpace) as? NSData {
            if let space = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSURLProtectionSpace {
                if let credential = NSURLCredentialStorage.sharedCredentialStorage().credentialsForProtectionSpace(space).objectEnumerator().nextObject() as? NSURLCredential {
                    let url = NSURLComponents()
                    url.host = space.host;
                    url.scheme = space.`protocol`

                    self.client.authenticate(baseURL: url.URL.absoluteString, user: credential.user, password: credential.password) {
                        (responseCredential, response, error) in

                        println("from keychain: \(responseCredential)")
                        if (!responseCredential) {
                            NSURLCredentialStorage.sharedCredentialStorage().removeCredential(credential, forProtectionSpace: space)
                        }
                    }
                }
            }
        }

        let authenticationCallback = { [weak self]
            (credential: NSURLCredential!, response: NSURLResponse!,
            error: NSError!) -> Void in

            println("from login box: \(credential)")
            if credential {
                let protectionSpace = NSURLProtectionSpace(host: self?.client.urlComponents?.host, port: 0, `protocol`: self?.client.urlComponents?.scheme, realm: nil, authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

                NSURLCredentialStorage.sharedCredentialStorage().setCredential(credential, forProtectionSpace: protectionSpace)

                let data = NSKeyedArchiver.archivedDataWithRootObject(protectionSpace)
                if data {
                    NSUserDefaults.standardUserDefaults().setObject(data!, forKey: ProtectionSpace)
                }
            }
        }

        loginViewController = LoginViewController() {
            [weak self] (server, user, password) in

            if self {
                self!.client.authenticate(baseURL: server, user: user, password: password, completion: authenticationCallback)
            }
        }

        if let viewController = loginViewController {
            window.contentView.addSubview(viewController.view)
        }
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
    }

//    @IBAction func artistsPressed(sender : NSButton) {
//        if let client = self.client {
//            client.artists {
//                data, response, error in
//                NSLog("data: \(data)\nresponse: \(response)\nerror: \(error)")
//            }
//        }
//    }
}

