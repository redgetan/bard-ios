//
//  Analytics.swift
//  Bard
//
//  Created by Reginald Tan on 2016-08-02.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import Firebase


class Analytics {
    static func identify(createdAt createdAt: NSDate? = nil) {
    }    
  
    static func track(event: String, properties: [String : NSObject]?) {
        
        FIRAnalytics.logEventWithName(event, parameters: properties)
    }
}
