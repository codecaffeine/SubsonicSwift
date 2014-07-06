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
    @lazy var artistViewController = ArtistsViewController()

    init() {
        client = SubsonicClient(appName: AppName,
            sessionConfig: NSURLSessionConfiguration.defaultSessionConfiguration())
        super.init()
    }

    func saveNewCredentialToKeychain(credential: NSURLCredential) {
        let protectionSpace = NSURLProtectionSpace(host: self.client.urlComponents?.host, port: 0, `protocol`: self.client.urlComponents?.scheme, realm: nil, authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

        NSURLCredentialStorage.sharedCredentialStorage().setCredential(credential, forProtectionSpace: protectionSpace)

        let data = NSKeyedArchiver.archivedDataWithRootObject(protectionSpace)
        if data {
            NSUserDefaults.standardUserDefaults().setObject(data!, forKey: ProtectionSpace)
        }
    }

    func removeOldCredentialFromKeychain() {
        if let data = NSUserDefaults.standardUserDefaults().objectForKey(ProtectionSpace) as? NSData {
            if let space = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSURLProtectionSpace {
                if let credentials = NSURLCredentialStorage.sharedCredentialStorage().credentialsForProtectionSpace(space) {
                    if let credential = credentials.objectEnumerator().nextObject() as? NSURLCredential {
                        NSURLCredentialStorage.sharedCredentialStorage().removeCredential(credential, forProtectionSpace: space)
                    }
                }
            }
            NSUserDefaults.standardUserDefaults().removeObjectForKey(ProtectionSpace)
        }
    }

    func loadArtists() {
        self.client.artists {
            [weak self] (artists, reponse, error) in

            if let artistsVC = self?.artistViewController {
                artistsVC.artists = artists
            }

            if error {
                println("error: \(error)")
            }
        }
    }

    func applicationDidFinishLaunching(aNotification: NSNotification?) {

        let authenticationCallback = {
            [weak self] (credential: NSURLCredential!, response: NSURLResponse!, error: NSError!) -> Void in

            if credential {
                self?.saveNewCredentialToKeychain(credential)
                self?.loadArtists()
                if let contentView = self?.window.contentView as? NSView {
                    self?.loginViewController?.view.removeFromSuperview()
                    contentView.addSubview(self?.artistViewController.view)
                }
            } else {
                self?.removeOldCredentialFromKeychain()
            }
        }

        if let data = NSUserDefaults.standardUserDefaults().objectForKey(ProtectionSpace) as? NSData {
            if let space = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSURLProtectionSpace {
                if let credentials = NSURLCredentialStorage.sharedCredentialStorage().credentialsForProtectionSpace(space) {
                    if let credential = credentials.objectEnumerator().nextObject() as? NSURLCredential {
                        let url = NSURLComponents()
                        url.host = space.host;
                        url.scheme = space.`protocol`

                        self.client.authenticate(baseURL: url.URL.absoluteString, user: credential.user, password: credential.password, completion: authenticationCallback)
                    }
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

}

