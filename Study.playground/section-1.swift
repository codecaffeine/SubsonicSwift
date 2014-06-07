// Playground - noun: a place where people can play

import Cocoa

let params = ["v": "1.10.2", "c": "Matt’s Awesome App", "f": "json"]

let server = "http://redgibson.subsonic.org";
let method = "ping.view";


extension String {
    var percentEncodedAll: String {
    let allowedCharacters = NSCharacterSet(charactersInString:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")
        return self.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
    }
}

let foo = "Matt’s Awesome App"
let bar = foo.percentEncodedAll

let characterSet = NSCharacterSet(charactersInString:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")

var htmlParams = String[]()
for (key, value) in params {
    htmlParams += "\(key.stringByAddingPercentEncodingWithAllowedCharacters(characterSet))=\(value.stringByAddingPercentEncodingWithAllowedCharacters(characterSet))"
}

var paramString = NSArray(array:htmlParams).componentsJoinedByString("&")

let base64Data = "foobar".dataUsingEncoding(NSUTF8StringEncoding)
let qwerty = base64Data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())


extension NSURLCredential {
    var basicAuthenticationString: String {
        let base64Data = "\(self.user):\(self.password)".dataUsingEncoding(NSUTF8StringEncoding)
        let base64String = base64Data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
        return "Basic \(base64String)";
    }
}

let ba = cred.basicAuthenticationString

