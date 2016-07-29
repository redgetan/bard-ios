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
import Haneke

class SceneSelectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var scenesTableView: UITableView!
    
    var scenes: Results<Scene>? = nil
    let cellIdentifier = "SceneTableViewCell"
    var characterToken = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initScenes()
        scenesTableView.delegate = self
        scenesTableView.dataSource = self
        
        syncRemoteData()
    }
    
    func initScenes() {
        self.scenes = try! Realm().objects(Scene.self)
            .filter("characterToken = '\(characterToken)'")
            .sorted("createdAt", ascending: false)
    }
    
    func syncRemoteData() {
        BardClient.getSceneList(characterToken, success: { value in
            for values in (value as? NSArray)! {
                Scene.create(values)
            }
            self.scenesTableView.reloadData()
            }, failure: { errorMessage in
                if Scene.count == 0 {
                    Drop.down("Failed to list scenes from the network", state: .Error, duration: 3)
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
        return self.scenes!.count;
        
    }
    
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let scene = self.scenes![indexPath.row]
        
        let cell = scenesTableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SceneTableViewCell
        cell.sceneNameLabel?.text = scene.name
        
        if let url = NSURL(string: scene.thumbnailUrl) {
            cell.sceneImageView.hnk_setImageFromURL(url)
        }

        return cell;
    }
 
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "sceneToEditor") {
            let indexPath = scenesTableView.indexPathForCell(sender as! UITableViewCell)!
            let scene = self.scenes![indexPath.row]
            let viewController = segue.destinationViewController as! BardEditorViewController;
            viewController.characterToken = scene.characterToken
            viewController.sceneToken     = scene.token

        }
    }
    
    
}
