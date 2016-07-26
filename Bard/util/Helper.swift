//
//  Helper.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-25.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit

class Helper {
    static func openStoryboard(window window: UIWindow? = nil, sourceViewController: UIViewController? = nil, storyboardName: String, viewControllerName: String) {
        // http://stackoverflow.com/questions/19962276/best-practices-for-storyboard-login-screen-handling-clearing-of-data-upon-logou
        // http://www.newventuresoftware.com/blog/organizing-xcode-projects-using-multiple-storyboards
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let targetViewController = storyboard.instantiateViewControllerWithIdentifier(viewControllerName)
        
        if window != nil {
            window!.rootViewController = targetViewController
        } else if sourceViewController != nil {
            sourceViewController!.presentViewController(targetViewController, animated: true, completion: nil)
        }
    }
}
