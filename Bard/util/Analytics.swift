//
//  Analytics.swift
//  Bard
//
//  Created by Reginald Tan on 2016-08-02.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import Mixpanel

class Analytics {
    static func identify(createdAt createdAt: NSDate? = nil) {
        let mixpanel = Mixpanel.sharedInstance()
        if let username = UserConfig.getUsername() {
            mixpanel.identify(username)
            mixpanel.people.set("$name", to: username)
            mixpanel.people.set("$email", to: UserConfig.getEmail()!)
            if let signupDate = createdAt {
                mixpanel.people.set("$created", to: signupDate)
            }
        }
        
    }
    
    static func timeEvent(event: String) {
        Mixpanel.sharedInstance().timeEvent(event)
    }
    
    static func track(event: String, properties: [NSObject : AnyObject]?) {
        let mixpanel = Mixpanel.sharedInstance()

        mixpanel.track(event, properties: properties)
    }
}
