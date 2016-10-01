//
//  SignupInputViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-25.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import SwiftyDrop
import TTTAttributedLabel

class SignupInputViewController: UIViewController, TTTAttributedLabelDelegate {

    
    @IBOutlet weak var usernameTextField: BorderedTextField!
    @IBOutlet weak var emailTextField: BorderedTextField!
    
    @IBOutlet weak var passwordTextField: BorderedTextField!
    @IBOutlet weak var termsAndPrivacyLabel: TTTAttributedLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTermsAndPrivacyLinks()
    }
    
    func initTermsAndPrivacyLinks() {
        termsAndPrivacyLabel.delegate = self
        termsAndPrivacyLabel.linkAttributes = [
            NSForegroundColorAttributeName: UIColor.grayColor(),
            NSUnderlineStyleAttributeName: false
        ]
        
        let termsRange = NSString(string: termsAndPrivacyLabel.text!).rangeOfString("Terms of Use")
        termsAndPrivacyLabel.addLinkToURL(
            NSURL(string: "https://bard.co/terms"),
            withRange: termsRange)
        
        let privacyRange = NSString(string: termsAndPrivacyLabel.text!).rangeOfString("Privacy Policy")
        termsAndPrivacyLabel.addLinkToURL(
            NSURL(string: "https://bard.co/privacy"),
            withRange: privacyRange)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func doSignUp(sender: UIButton) {
        BardClient.signUp(username: self.usernameTextField.text!,
                            email: self.emailTextField.text!,
                            password: self.passwordTextField.text!, success: { value in
            Drop.down("Account successfully created", state: .Success, duration: 2)
            UserConfig.storeCredentials(value)
            Analytics.identify(createdAt: NSDate())
            self.dismissViewControllerAnimated(true, completion: nil)


        }, failure: { errorMessage in
            Drop.down(errorMessage, state: .Error, duration: 3)
        })
    }
    
    // MARK: TTTAttributedLabelDelegate
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }

  
}
