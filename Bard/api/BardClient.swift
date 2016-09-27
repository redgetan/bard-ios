//
//  BardClient.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-25.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import Alamofire

class BardClient {
 
    
    static let signUpUrl = "\(Configuration.bardAccountBaseURL)/users"
    static let loginUrl  = "\(Configuration.bardAccountBaseURL)/users/sign_in"
    static let characterListUrl  = "\(Configuration.bardAccountBaseURL)/bundles"
    
    static func getSceneListUrl(characterToken: String) -> String  {
        return "\(Configuration.bardAccountBaseURL)/bundles/\(characterToken)/scenes"
    }

    static func getSceneWordListUrl(characterToken: String, sceneToken: String) -> String  {
        return "\(Configuration.bardAccountBaseURL)/bundles/\(characterToken)/scenes/\(sceneToken)/word_list"
    }
    
    static func getCharacterWordListUrl(characterToken: String) -> String {
        return "\(Configuration.bardAccountBaseURL)/bundles/\(characterToken)/word_list"
    }
    
    static func postRepoUrl() -> String {
        return "\(Configuration.bardAccountBaseURL)/repos"
    }
    
    
    static func login(usernameOrEmail usernameOrEmail: String, password: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) {
        
        let params : [String : String] = [
            "email"    : usernameOrEmail,
            "password" : password
        ]
        
        bardApiRequest(.POST, url: loginUrl, parameters: params, success: success, failure: failure)
    }
    
    static func signUp(username username: String, email: String, password: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) {
        
        let params : [String : String] = [
            "username" : username,
            "email"    : email,
            "password" : password
        ]
        
        bardApiRequest(.POST, url: signUpUrl, parameters: params, success: success, failure: failure)
    }
    
    static func getCharacterList(success success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        bardApiRequest(.GET, url: characterListUrl, success: success, failure: failure)
    }
    
    static func getSceneList(characterToken: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        bardApiRequest(.GET, url: getSceneListUrl(characterToken), success: success, failure: failure)
    }
    
    static func getSceneWordList(characterToken: String, sceneToken: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        bardApiRequest(.GET, url: getSceneWordListUrl(characterToken, sceneToken: sceneToken), success: success, failure: failure)
    }
    
    static func getCharacterWordList(characterToken: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        bardApiRequest(.GET, url: getCharacterWordListUrl(characterToken), success: success, failure: failure)
    }
    
    static func postRepo(uuid: String, characterToken: String, wordList: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil) {
        let params : [String : String] = [
            "uuid": uuid,
            "character_token" : characterToken,
            "word_list" : wordList
        ]
        bardApiRequest(.POST, url: postRepoUrl(), parameters: params, success: success, failure: failure)
    }
    
    static func bardApiRequest(method: Alamofire.Method, url: String, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) {

        var customHeaders = headers ?? [String : String]()
        customHeaders["Accept"] = "application/json"
        
        if let authenticationToken = UserConfig.getAuthenticationToken() {
            customHeaders["Authorization"] = "Token \(authenticationToken)"
        }
        
        apiRequest(method, url: url, parameters: parameters, headers: customHeaders, success: success, failure: failure)
    }
    
    static func apiRequest(method: Alamofire.Method, url: String, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) {
        
        Alamofire.request(method, url, parameters: parameters, headers: headers)
            .responseJSON { response in
                if let httpError = response.result.error {
                    failure?(httpError.localizedDescription)
                } else if let JSON = (response.result.value  as? [String:AnyObject]) {
                    if let appError = JSON["error"] as? String {
                        print(appError)
                        failure?(appError)
                    } else {
                        success?(JSON)
                    }
                }
        }
    }
}

