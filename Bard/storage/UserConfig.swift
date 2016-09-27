//
//  UserSettings.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-24.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import KeychainAccess

class UserConfig {
    
    static let keychain: Keychain = Keychain(service: Configuration.keychainService)
    
    static func isLogined() -> Bool {
        return NSUserDefaults.standardUserDefaults().objectForKey("is_user_logined") != nil
    }
    
    static func storeCredentials(userDetails: AnyObject) {
        let dict = (userDetails as! [String:AnyObject])
        let username  = dict["username"] as? String
        let email     = dict["email"] as? String
        let authToken = dict["authenticationToken"] as? String

        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(true, forKey: "is_user_logined")
        defaults.setObject(username, forKey: "username")
        defaults.setObject(email, forKey: "email")
        defaults.synchronize()
        
        keychain["authentication_token"] = authToken
    }
    
    static func clearCredentials() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey("is_user_logined")
        defaults.removeObjectForKey("username")
        defaults.removeObjectForKey("email")
        defaults.synchronize()

        keychain["authentication_token"] = nil
    }
    
    static func getUsername() -> String {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.stringForKey("username")!
    }
    
    static func getEmail() -> String {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.stringForKey("email")!
    }
    
    static func getAuthenticationToken() -> String {
        return keychain["authentication_token"]!
    }
    
}