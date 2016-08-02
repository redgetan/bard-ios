//
//  SecondViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-24.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var profilesTableView: UITableView!
    
    let cellIdentifier = "ProfileTableViewCell"
    
    enum Row: Int {
        case About
        case Feedback
        case TellFriend
        case Logout
        case RowCount
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initProfileHeader()
        profilesTableView.delegate = self
        profilesTableView.dataSource = self
    }
    
    func initProfileHeader() {
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
//        self.profileImageView.layer.borderWidth = 2.0
//        self.profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
        self.usernameLabel.text = UserConfig.getUsername()
        self.emailLabel.text = UserConfig.getEmail()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return Row.RowCount.rawValue
    }
    
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let row = Row(rawValue: indexPath.row) else {
            fatalError()
        }
        
        let cell = profilesTableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        
        switch row {
        case .About:
            cell.textLabel?.text = "About"
            break
        case .Feedback:
            cell.textLabel?.text = "Feedback"
            break
        case .TellFriend:
            cell.textLabel?.text = "Tell a Friend"
            break
        case .Logout:
            cell.textLabel?.text = "Logout"
            break
        default:
            break
        }
        
        return cell;
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let row = Row(rawValue: indexPath.row) else {
            fatalError()
        }
        
        switch row {
        case .About:
            UIApplication.sharedApplication().openURL(NSURL(string: "https://bard.co")!)
            break
        case .Feedback:
            Instabug.invoke()
            break
        case .TellFriend:
            let textToShare = "This app converts your text into a video of an actor saying them"
            
            if let url = NSURL(string: "https://bard.co/") {
                let objectsToShare = [textToShare, url]
                let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                self.presentViewController(activityViewController, animated: true, completion: nil)
            }
            break
        case .Logout:
            UserConfig.clearCredentials()
            Helper.openStoryboard(sourceViewController: self,
                                  storyboardName: "Login",
                                  viewControllerName: "LoginNavigationController")
            break
        default:
            break
        }
        
    }
    


}

