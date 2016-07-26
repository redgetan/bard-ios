//
//  SignupInputViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-25.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import SwiftyDrop

class SignupInputViewController: UIViewController {

    
    @IBOutlet weak var usernameTextField: BorderedTextField!
    @IBOutlet weak var emailTextField: BorderedTextField!
    
    @IBOutlet weak var passwordTextField: BorderedTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func doSignUp(sender: UIButton) {

        
        BardClient.signUp(username: self.usernameTextField.text!,
                            email: self.emailTextField.text!,
                            password: self.passwordTextField.text!, success: { value in
            Drop.down("Account successfully created", state: .Success, duration: 2)
            UserConfig.storeCredentials(value)
        }, failure: { errorMessage in
            Drop.down(errorMessage, state: .Error, duration: 3)
        })
    }
  
}
