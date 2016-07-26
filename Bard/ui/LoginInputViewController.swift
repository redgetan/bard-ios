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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    @IBAction func doLogin(sender: UIButton) {
        var x: String? = nil
        let result = x!.isEmpty
        BardClient.login(usernameOrEmail: usernameOrEmailTextField.text!,
                         password: passwordTextField.text!, success: { value in
            UserConfig.storeCredentials(value)
            Helper.openStoryboard(sourceViewController: self, storyboardName: "Main", viewControllerName: "TabBarController")
            }, failure: { errorMessage in
            Drop.down(errorMessage, state: .Error, duration: 3)
        })
    }

}

