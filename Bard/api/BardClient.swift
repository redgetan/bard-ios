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
 
    
    static func getSignUpURL() -> String {
        return "\(Configuration.bardAccountBaseURL)/users"
    }
    
    static func signUp(username username: String, email: String, password: String, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) {
        
        let params : [String : String] = [
            "username" : username,
            "email"    : email,
            "password" : password
        ]
        
        bardApiRequest(.POST, url: getSignUpURL(), parameters: params, success: success, failure: failure)
    }
    
    static func bardApiRequest(method: Alamofire.Method, url: String, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) {

        var customHeaders = headers ?? [String : String]()
        customHeaders["Accept"] = "application/json"
        
        apiRequest(method, url: url, parameters: parameters, headers: customHeaders, success: success, failure: failure)
    }
    
    static func apiRequest(method: Alamofire.Method, url: String, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil, success: (AnyObject -> Void)? = nil, failure: (String -> Void)? = nil ) {
        
        Alamofire.request(method, url, parameters: parameters, headers: headers)
            .responseJSON { response in
                if let httpError = response.result.error {
                    failure?(httpError.localizedDescription)
                } else if let JSON = response.result.value {
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

