//
//  FirstViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-24.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import RealmSwift
import DZNEmptyDataSet
import SwiftyDrop

class RepositoriesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var repositoriesTableView: UITableView!
    var repositories: Results<Repository>? = nil
    let cellIdentifier = "RepositoryTableViewCell"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Storage.setup()
        initRepositories()
        
        repositoriesTableView.delegate = self
        repositoriesTableView.dataSource = self
        repositoriesTableView.emptyDataSetSource = self
        repositoriesTableView.emptyDataSetDelegate = self
       
        // A little trick for removing the cell separators
        repositoriesTableView.tableFooterView = UIView()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        repositoriesTableView.reloadData()
    }
    
    func initRepositories() {
        self.repositories = try! Realm().objects(Repository.self)
                                        .filter("username = '\(UserConfig.getUsername())'")
                                        .sorted("createdAt", ascending: false)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return self.repositories!.count
    }
    
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let repository = self.repositories![indexPath.row]
        
        let cell = repositoriesTableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = repository.details()
        
        if let uiImage = repository.getUIImage() {
            cell.imageView?.image = uiImage
        }
        
        return cell;
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let repository = self.repositories![indexPath.row]
            BardClient.deleteRepo(repository.getToken(), success: { result in
                Storage.removeFile(repository.getFilePath())
                repository.delete()
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }, failure: { error in
                Drop.down(error, state: .Error, duration: 2)
                print("unable to delete remote repo")
            })
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "repositoryToPlayer") {
            let indexPath = repositoriesTableView.indexPathForCell(sender as! UITableViewCell)!
            let repository = self.repositories![indexPath.row]
            let viewController = segue.destinationViewController as! VideoPlayerViewController;
            viewController.repository = repository
        }
    }
    
    
    // MARK: DZNEmptyDataSetSource
    
    func titleForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
        let text = "Create your first Bard"
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
                          NSForegroundColorAttributeName: UIColor.darkGrayColor()]
    
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
        let text = "To start, click the button on upper-right corner."
    
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraph.alignment = .Center
        
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(14.0),
                          NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                          NSParagraphStyleAttributeName: paragraph]
        
        return NSAttributedString(string: text, attributes: attributes)
    }


}

