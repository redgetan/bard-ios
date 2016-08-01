//
//  SecondViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-24.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var profilesTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
        self.profileImageView.layer.borderWidth = 2.0
        self.profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
        self.usernameLabel.text = UserConfig.getUsername()
        self.emailLabel.text = UserConfig.getEmail()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

