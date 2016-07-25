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
    
    static var bardAccountBaseURL: String {
        get {
            return "http://localhost:3000"
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    #else
    
    
    
    
    
    
    
    static var bardAccountBaseURL: String {
        get {
            return "http://bard.zrqp9xghrt.us-west-2.elasticbeanstalk.com"
        }
    }
    
    #endif
    
}