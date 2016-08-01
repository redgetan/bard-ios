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

class RepositoriesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var repositoriesTableView: UITableView!
    var repositories: Results<Repository>? = nil
    let cellIdentifier = "RepositoryTableViewCell"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initRepositories()
        
        repositoriesTableView.delegate = self
        repositoriesTableView.dataSource = self
        repositoriesTableView.emptyDataSetSource = self
        repositoriesTableView.emptyDataSetDelegate = self
       
        // A little trick for removing the cell separators
        repositoriesTableView.tableFooterView = UIView()

    }
    
    func initRepositories() {
        self.repositories = try! Realm().objects(Repository.self).sorted("createdAt", ascending: false)
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
        let text = "To start using the text-to-video app, click the button on upper-right corner."
    
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraph.alignment = .Center
        
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(14.0),
                          NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                          NSParagraphStyleAttributeName: paragraph]
        
        return NSAttributedString(string: text, attributes: attributes)
    }


}

