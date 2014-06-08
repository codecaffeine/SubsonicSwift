//
//  AppDelegate.swift
//  SubsonicSwift
//
//  Created by Matt Thomas on 6/3/14.
//  Copyright (c) 2014 Matt Thomas. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet var serverField : NSTextField
    @IBOutlet var usernameField : NSTextField
    @IBOutlet var passwordField : NSSecureTextField
    @IBOutlet var window: NSWindow
    var client: SubsonicClient?

    func applicationDidFinishLaunching(aNotification: NSNotification?) {
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
    }

    @IBAction func pingPressed(sender : AnyObject) {
        self.client = SubsonicClient(
            appName: "Matt’s Awesome App",
            baseURL: serverField.stringValue,
            username: usernameField.stringValue,
            password: passwordField.stringValue)

        if let client = self.client {
            client.ping {
                (data, response, error) in
                NSLog("data: \(data)\nresponse: \(response)\nerror: \(error)")
            }
        }
    }
    @IBAction func artistsPressed(sender : NSButton) {
        if let client = self.client {
            client.artists {
                data, response, error in
                NSLog("data: \(data)\nresponse: \(response)\nerror: \(error)")
            }
        }
    }
}

