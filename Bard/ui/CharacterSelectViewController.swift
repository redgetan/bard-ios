//
//  CharacterSelectViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-26.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyDrop
import DZNEmptyDataSet

class CharacterSelectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
                                     DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var charactersTableView: UITableView!
    var characters: Results<Character>? = nil
    let cellIdentifier = "CharacterTableViewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backButton
        
        initCharacters()
        charactersTableView.delegate = self
        charactersTableView.dataSource = self
        self.charactersTableView.emptyDataSetSource = self
        self.charactersTableView.emptyDataSetDelegate = self

        syncRemoteData()
    }
    
    func initCharacters() {
        self.characters = try! Realm().objects(Character.self)
                                      .sorted("createdAt", ascending: false)
    }
    
    func syncRemoteData() {
        BardClient.getCharacterList(success: { value in
            for characterValues in (value as? NSArray)! {
                Character.create(characterValues)
            }
            self.charactersTableView.reloadData()
        }, failure: { errorMessage in
            if self.characters?.count == 0 {
//                Drop.down("Failed to list characters from the network", state: .Error, duration: 3)
//                self.charactersTableView.emptyDataSetSource = self
//                self.charactersTableView.emptyDataSetDelegate = self
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return self.characters!.count;
        
    }
    
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let character = self.characters![indexPath.row]
        
        let cell = charactersTableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = character.name
        cell.detailTextLabel?.text = character.details
        return cell;
    }
 
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "characterToEditor") {
            let indexPath = charactersTableView.indexPathForCell(sender as! UITableViewCell)!
            let character = self.characters![indexPath.row]
            Analytics.track("compose", properties: ["characterToken" : character.token,
                                                    "character" : character.name])
            BardLogger.log("characterSelect: \(character.name) - \(character.token)")
            _ = segue.destinationViewController as! BardEditorViewController;
//            viewController.character = character
        }
    }
    
    // MARK: DZNEmptyDataSetSource
    
    func titleForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
        let text = "Unable to fetch data"
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
                          NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
        let text = "Please make sure that you are connected to the internet."
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraph.alignment = .Center
        
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(14.0),
                          NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                          NSParagraphStyleAttributeName: paragraph]
        
        return NSAttributedString(string: text, attributes: attributes)
    }


}
