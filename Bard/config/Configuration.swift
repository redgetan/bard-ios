//
//  Configuration.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-25.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation

class Configuration {
    
    #if DEBUG
    
    static let bardAccountBaseURL = "https://bard.co"
    static let keychainService    = "co.bard.auth-token-debug"
    

    
    #else
    
    static let bardAccountBaseURL = "https://bard.co"
    static let keychainService    = "co.bard.auth-token"
    
    
    #endif
    
}