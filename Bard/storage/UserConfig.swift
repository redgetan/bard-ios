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
        let dict = userDetails as! [String: String]
        let username  = dict["username"]!
        let email     = dict["email"]!
        let authToken = dict["authenticationToken"]!
        print(authToken)

        do {
            try keychain.set(authToken,key: "authentication_token")
        } catch let error {
            print(error)
        }

        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(true, forKey: "is_user_logined")
        defaults.setObject(username, forKey: "username")
        defaults.setObject(email, forKey: "email")
        defaults.synchronize()
        
    }
 
    static func clearCredentials() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey("is_user_logined")
        defaults.removeObjectForKey("username")
        defaults.removeObjectForKey("email")
        defaults.synchronize()

        keychain["authentication_token"] = nil
    }
    
    static func getUsername() -> String? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.stringForKey("username") 
    }
    
    static func getEmail() -> String? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.stringForKey("email")
    }
    
    
    static func setIsUploading(isUploading: Bool) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(isUploading, forKey: "isUploading")
        defaults.synchronize()
    }
    
    static func getIsUploading() -> Bool? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.boolForKey("isUploading")
    }
    
    static func setCurrentUploadSceneToken(uploadSceneToken: String) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(uploadSceneToken, forKey: "uploadSceneToken")
        defaults.synchronize()
    }
    
    static func getCurrentUploadSceneToken() -> String? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.stringForKey("uploadSceneToken")
    }
    
    static func setCurrentUploadSceneName(uploadSceneName: String) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(uploadSceneName, forKey: "uploadSceneName")
        defaults.synchronize()
    }
    
    static func getCurrentUploadSceneName() -> String? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.stringForKey("uploadSceneName")
    }
    
    
    static func getAuthenticationToken() -> String? {
        let token = keychain[string: "authentication_token"]
        return token
    }
    
}
