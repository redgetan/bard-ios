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
        BardClient.login(usernameOrEmail: usernameOrEmailTextField.text!,
                         password: passwordTextField.text!, success: { value in
            UserConfig.storeCredentials(value)
            }, failure: { errorMessage in
            Drop.down(errorMessage, state: .Error, duration: 3)
        })
    }

}

