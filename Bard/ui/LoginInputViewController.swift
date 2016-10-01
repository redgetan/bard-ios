//
//  LoginInputViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-25.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import SwiftyDrop

class LoginInputViewController: UIViewController {

    @IBOutlet weak var usernameOrEmailTextField: BorderedTextField!
    @IBOutlet weak var passwordTextField: BorderedTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        if UserConfig.isLogined() {
            Helper.openStoryboard(sourceViewController: self, storyboardName: "Main", viewControllerName: "TabBarViewController")
        }
        */
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if UserConfig.isLogined() {
            Helper.openStoryboard(sourceViewController: self, storyboardName: "Main", viewControllerName: "TabBarViewController")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)

    }

    @IBAction func doLogin(sender: UIButton) {
        BardClient.login(usernameOrEmail: usernameOrEmailTextField.text!,
                         password: passwordTextField.text!, success: { value in
            UserConfig.storeCredentials(value)
            Analytics.identify()
            self.dismissViewControllerAnimated(true, completion: nil)

            }, failure: { errorMessage in
            Drop.down(errorMessage, state: .Error, duration: 3)
        })
    }

}

