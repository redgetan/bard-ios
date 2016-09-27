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
    
    static let bardAccountBaseURL = "http://localhost:3000"
    static let keychainService    = "co.bard.auth-token-debug"
    static let s3UserBucket       = "roplabs-bard-users-staging"
    static let awsCognitoPoolId   = "us-west-2:7bd4263f-57f2-4d08-9855-7672299d73d4"

    
    #else
    
    static let bardAccountBaseURL = "https://bard.co"
    static let keychainService    = "co.bard.auth-token"
    static let s3UserBucket       = "roplabs-bard-users"
    static let awsCognitoPoolId   = "us-west-2:a42a156a-30f6-4fb7-a2ea-78599fa4d180"
    
    
    #endif
    
}