//
//  Helper.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-25.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import SCLAlertView
import MBProgressHUD


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
    
    static func showDownloadProgress(view: UIView, message: String) -> MBProgressHUD {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.label.text = message
        hud.mode = .AnnularDeterminate
        return hud
    }
    
    static func showProgress(view: UIView, message: String) -> MBProgressHUD {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.label.text = message
        hud.mode = .Indeterminate
        return hud
    }
    
    static func makeHUDCancelable(hud: MBProgressHUD, tap: UITapGestureRecognizer) {
        hud.detailsLabel.text = "Tap to cancel"
        hud.addGestureRecognizer(tap)
    }
    
    static func hideProgress(view: UIView) {
        MBProgressHUD.hideHUDForView(view,animated: true)
    }
    
    static func showAskUserToLogin(viewController :UIViewController, message: String) {
        let appearance = SCLAlertView.SCLAppearance(hideWhenBackgroundViewIsTapped: true,
                                                    showCloseButton: false)
        let alertView  = SCLAlertView(appearance: appearance)
        
        alertView.addButton("Login") {
            Helper.openStoryboard(sourceViewController: viewController,
                                  storyboardName: "Login",
                                  viewControllerName: "LoginNavigationController")
        }
        
        alertView.addButton("Register") {
            Helper.openStoryboard(sourceViewController: viewController,
                                  storyboardName: "Login",
                                  viewControllerName: "SignupNavigationController")
        }
        
        alertView.showEdit("", subTitle: message,
                           colorStyle: 0x704DEF,
                           duration: 10.0)
    }

    
    // http://stackoverflow.com/a/23157272/803865
    static func addBorder(view: UIView, edges: UIRectEdge, colour: UIColor = UIColor.whiteColor(), thickness: CGFloat = 1) -> [UIView] {
        
        var borders = [UIView]()
        
        func border() -> UIView {
            let border = UIView(frame: CGRectZero)
            border.backgroundColor = colour
            border.translatesAutoresizingMaskIntoConstraints = false
            return border
        }
        
        if edges.contains(.Top) || edges.contains(.All) {
            let top = border()
            view.addSubview(top)
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[top(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["top": top]))
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[top]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["top": top]))
            borders.append(top)
        }
        
        if edges.contains(.Left) || edges.contains(.All) {
            let left = border()
            view.addSubview(left)
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[left(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["left": left]))
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[left]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["left": left]))
            borders.append(left)
        }
        
        if edges.contains(.Right) || edges.contains(.All) {
            let right = border()
            view.addSubview(right)
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:[right(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["right": right]))
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[right]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["right": right]))
            borders.append(right)
        }
        
        if edges.contains(.Bottom) || edges.contains(.All) {
            let bottom = border()
            view.addSubview(bottom)
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:[bottom(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["bottom": bottom]))
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[bottom]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["bottom": bottom]))
            borders.append(bottom)
        }
        
        return borders
    }
    
    // http://stackoverflow.com/a/27880748/803865
    static func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        
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
    
    // https://coderwall.com/p/6onn0g/adding-progress-icon-programmatically-to-a-new-uiview
    
    static func addActivityIndicator(view: UIView) -> UIActivityIndicatorView {
        let progressIcon = UIActivityIndicatorView()
        progressIcon.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        // http://stackoverflow.com/a/10781464
        progressIcon.center = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
        view.addSubview(progressIcon)
        view.bringSubviewToFront(progressIcon)
        
        return progressIcon
    }
    
    static func matchesForRegexInRange(regex: String!, text: String!) -> [NSRange] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map {$0.range}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
