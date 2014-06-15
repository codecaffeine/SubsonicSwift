//
//  LoginViewController.swift
//  SubsonicSwift
//
//  Created by Matt Thomas on 6/13/14.
//  Copyright (c) 2014 Matt Thomas. All rights reserved.
//

import Cocoa

class LoginViewController: NSViewController {

    @IBOutlet var serverField : NSTextField
    @IBOutlet var userField : NSTextField
    @IBOutlet var passwordField : NSSecureTextField
    @IBOutlet var signInButton : NSButton

    let signInAction: ((server: String, user: String, password: String) -> Void)


    init(signInAction: ((server: String, user: String, password: String) -> Void)) {
        self.signInAction = signInAction
        super.init(nibName: "LoginViewController", bundle: nil)
    }

    @IBAction func signInPressed(sender : AnyObject) {
        signInAction(server: serverField.stringValue, user: userField.stringValue, password: passwordField.stringValue)
    }
}
