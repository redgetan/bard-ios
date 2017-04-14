//
//  PackSelectViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-26.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyDrop
import DZNEmptyDataSet

class PackSelectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
                                     DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var charactersTableView: UITableView!
    var packs: Results<Pack>? = nil
    let cellIdentifier = "CharacterTableViewCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        let backButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backButton

        initPacks()
        charactersTableView.delegate = self
        charactersTableView.dataSource = self
        self.charactersTableView.emptyDataSetSource = self
        self.charactersTableView.emptyDataSetDelegate = self

        syncRemoteData()
    }

    func initPacks() {
        self.packs = try! Realm().objects(Pack.self)
                                      .sorted("createdAt", ascending: false)
    }

    func syncRemoteData() {
        BardClient.getPackList(success: { value in
            for packValues in (value as? NSArray)! {
                Pack.create(packValues)
            }
            self.charactersTableView.reloadData()
        }, failure: { errorMessage in
            if self.packs?.count == 0 {
//                Drop.down("Failed to list packs from the network", state: .Error, duration: 3)
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
        return self.packs!.count;

    }

    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let pack = self.packs![indexPath.row]

        let cell = charactersTableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = pack.name
        cell.detailTextLabel?.text = pack.details
        return cell;
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "characterToEditor") {
            let indexPath = charactersTableView.indexPathForCell(sender as! UITableViewCell)!
            let pack = self.packs![indexPath.row]
            Analytics.track("compose", properties: ["packToken" : pack.token,
                                                    "pack" : pack.name])
            BardLogger.log("characterSelect: \(pack.name) - \(pack.token)")
            _ = segue.destinationViewController as! BardEditorViewController;
//            viewController.pack = pack
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
