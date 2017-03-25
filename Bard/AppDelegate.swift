//
//  AppDelegate.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-24.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import Firebase
import Mixpanel
import AWSCore
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        FIRApp.configure()
        
        Mixpanel.sharedInstanceWithToken(Configuration.mixpanelToken)
        Instabug.startWithToken("b95aeb23d36646812b25000303399919", invocationEvent: IBGInvocationEvent.None)
        FBSDKApplicationDelegate.sharedInstance().application(application,
            didFinishLaunchingWithOptions: launchOptions)

        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USWest2,
                                                                identityPoolId: Configuration.awsCognitoPoolId)
        
        let configuration = AWSServiceConfiguration(region:.USWest2, credentialsProvider:credentialsProvider)
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        performRealmMigration()
        setupNavigationBarColor()
        
        Helper.openStoryboard(window: window,
                                  storyboardName: "Main",
                                  viewControllerName: "TabBarViewController")
        return true
    }
    
    private func performRealmMigration() {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 1,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                
                if oldSchemaVersion < 1 {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            }
        ) 
        Realm.Configuration.defaultConfiguration = config
    }
    
    // http://stackoverflow.com/a/27929937/803865
    // http://stackoverflow.com/a/24687648/803865
    private func setupNavigationBarColor() {
        UINavigationBar.appearance().barTintColor = UIColor(hex: "#704DEF", alpha:1.0)
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    // http://stackoverflow.com/a/29282534
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)

    }
    
    // https://www.raywenderlich.com/128948/universal-links-make-connection
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            let url = userActivity.webpageURL!
            let universalLinkFullPath = url.path!
            let matched = self.regexMatches("scenes/(.+)/editor", text: universalLinkFullPath)
            if matched.count > 0 {
                let sceneToken = matched[0].componentsSeparatedByString("/")[1]
                print("universal link bard editor \(sceneToken)")
                self.openDeepLink(sceneToken)

                return true
            }
        }
        
        
        application.openURL(userActivity.webpageURL!)
        return false
    }
    
    func openDeepLink(sceneToken: String) {
        let storyboardName = "Main"
        let viewControllerName = "TabBarViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let targetViewController = storyboard.instantiateViewControllerWithIdentifier(viewControllerName) as! TabBarViewController
        targetViewController.sceneTokenDeepLink = sceneToken
        
        window!.rootViewController = targetViewController
        
    }
    
    func regexMatches(regex: String, text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substringWithRange($0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }


}

