//
//
//  Created by Reginald Tan on 2016-07-26.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyDrop
import DZNEmptyDataSet
import Haneke

class SceneSelectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate,DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var scenesTableView: UITableView!

    var scenes: [Scene] = []
    let cellIdentifier = "SceneTableViewCell"
    var totalRowsLoaded: Int = 0
    var totalPagesLoaded: Int = 0
    var isLoading: Bool = false
    var isEndOfPage: Bool = false
    var isSearching: Bool = false
    var activityIndicator: UIActivityIndicatorView? = nil
    var isSearchPerformed: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let backButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backButton

        initScenes()

        searchBar.delegate = self
        scenesTableView.delegate = self
        scenesTableView.dataSource = self
        scenesTableView.emptyDataSetSource = self
        scenesTableView.emptyDataSetDelegate = self


    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.activityIndicator = Helper.addActivityIndicator(self.view)
        self.activityIndicator?.startAnimating()

        syncRemoteData(self.totalPagesLoaded + 1)
    }

    func initScenes() {
        self.scenes = []
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.totalPagesLoaded = 0
        self.totalRowsLoaded = 0
        self.scenes = []
        self.isLoading = false
        self.isEndOfPage = false

        if self.isSearching {
            return
        }

        self.isSearching = true
        self.activityIndicator?.startAnimating()
        syncRemoteData(self.totalPagesLoaded + 1, search: searchBar.text)
    }

    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        let searchBarTextField: UITextField?

        let views = searchBar.subviews[0].subviews
        for subview in views {
            if (subview.isKindOfClass(UITextField))
            {
                searchBarTextField = subview as? UITextField
                searchBarTextField?.enablesReturnKeyAutomatically = false
                break
            }
        }

    }

    func syncRemoteData(pageIndex: Int, search: String? = nil) {
        var sceneToken: String = ""
        var scene: Scene?

        BardClient.getSceneList(pageIndex, search: search, success: { value in
            self.activityIndicator?.stopAnimating()
            self.isSearchPerformed = true

            for obj in (value as! NSArray) {
                let dict = (obj as! [String:AnyObject])

                sceneToken = dict["token"] as! String
                scene = Scene.forToken(sceneToken)

                if scene == nil {
                     // create scene if it didnt exist before
                    scene = Scene.create(dict)
                }

                if scene != nil {
                    self.scenes.append(scene!)
                    self.totalRowsLoaded += 1

                }

            }

            if (value as! NSArray).count == 0 {
                self.isEndOfPage = true
            } else {
                self.totalPagesLoaded += 1
            }


            self.scenesTableView.reloadData()
            self.isSearching = false

            }, failure: { errorMessage in
                self.isSearchPerformed = true
                self.activityIndicator?.stopAnimating()
                self.scenesTableView.reloadData()


                if self.scenes.count == 0 {
                    Drop.down("Failed to list scenes from the network", state: .Error, duration: 3)
                }

                self.isSearching = false
        })
    }

    func getScenesNextPage() {
        if (self.searchBar.text == nil) {
            syncRemoteData(self.totalPagesLoaded + 1)
        } else {
            syncRemoteData(self.totalPagesLoaded + 1, search: searchBar.text)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    func tableView(tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return self.scenes.count;

    }

    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = scenesTableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SceneTableViewCell




        let sceneIndex = indexPath.row
        let scene = self.scenes[sceneIndex]

        cell.sceneNameLabel?.text = scene.name


        // taglist
        cell.sceneTagListHeightConstraint.constant = 25
        if !scene.tagList.isEmpty {
            cell.sceneTagListLabel?.text = scene.tagList.componentsSeparatedByString(",").map { tag in
                "#\(tag)"
            }.joinWithSeparator(" ")
        } else {
            cell.sceneTagListLabel?.text = ""
            cell.sceneTagListHeightConstraint.constant = 0
        }

        // owner/trimmer name
        if !scene.labeler.isEmpty {
            cell.sceneOwnerLabel?.text = "by \(scene.labeler)"
        } else if !scene.owner.isEmpty {
            cell.sceneOwnerLabel?.text = "by \(scene.owner)"
        } else {
            cell.sceneOwnerLabel?.text = ""
        }

        if let url = NSURL(string: scene.thumbnailUrl) {
            cell.sceneImageView.hnk_setImageFromURL(url)
        }


        return cell
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        if (indexPath.row + 1  >= self.totalRowsLoaded && !isLoading && !isEndOfPage && !isSearching) {
            self.isLoading = true
            self.getScenesNextPage()
            self.isLoading = false

        }
    }


    @IBAction func cancel(sender: UIBarButtonItem) {
      dismissViewControllerAnimated(true, completion: nil)

    }




    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "sceneToEditor") {
            let indexPath = scenesTableView.indexPathForCell(sender as! UITableViewCell)!

            let sceneIndex = indexPath.row
            let scene = self.scenes[sceneIndex]
            Analytics.track("compose", properties: ["sceneToken" : scene.token,
                "scene" : scene.name])
            BardLogger.log("sceneSelect: \(scene.name) - \(scene.token)")
            let viewController = segue.destinationViewController as! BardEditorViewController;
            viewController.scene = scene


        }
    }

    // MARK: DZNEmptyDataSetSource

    func titleForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
        let text = ""
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
                          NSForegroundColorAttributeName: UIColor.darkGrayColor()]

        return NSAttributedString(string: text, attributes: attributes)
    }

    func descriptionForEmptyDataSet(scrollView: UIScrollView) -> NSAttributedString {
        let text = "No results found."

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraph.alignment = .Center

        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(14.0),
                          NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                          NSParagraphStyleAttributeName: paragraph]

        return NSAttributedString(string: text, attributes: attributes)
    }

    // MARK: DZNEmptyDataSetDelegate

    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        return isSearchPerformed;
    }


}
