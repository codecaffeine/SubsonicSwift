// Playground - noun: a place where people can play

import Cocoa

let params = ["v": "1.10.2", "c": "Matt’s Awesome App", "f": "json"]

let server = "http://redgibson.subsonic.org";
let method = "ping.view";

let characterSet = NSCharacterSet(charactersInString:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")

var htmlParams = String[]()
for (key, value) in params {
    htmlParams += "\(key.stringByAddingPercentEncodingWithAllowedCharacters(characterSet))=\(value.stringByAddingPercentEncodingWithAllowedCharacters(characterSet))"
}

var paramString = NSArray(array:htmlParams).componentsJoinedByString("&")

