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
import EZLoadingActivity

class SceneSelectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var scenesTableView: UITableView!
    
    var scenes: Results<Scene>? = nil
    var selectedScene: Scene? = nil
    let cellIdentifier = "SceneTableViewCell"
    var character: Character!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backButton
        
        initScenes()
        scenesTableView.delegate = self
        scenesTableView.dataSource = self
        
        syncRemoteData()
    }
    
    func initScenes() {
        self.scenes = try! Realm().objects(Scene.self)
            .filter("characterToken = '\(character.token)'")
            .sorted("createdAt", ascending: false)
    }
    
    func syncRemoteData() {
        var sceneToken: String = ""
        var thumbnailUrl: String = ""
        var sceneName: String = ""
        
        BardClient.getSceneList(character.token, success: { value in
            for obj in (value as? NSArray)! {
                sceneToken = obj["token"] as! String
                thumbnailUrl = obj["thumbnailUrl"] as! String
                sceneName = obj["name"] as! String
                if let scene = Scene.forToken(sceneToken) {
                    if scene.thumbnailUrl.isEmpty {
                        scene.setNameAndThumbnail(sceneName, thumbnailUrl: thumbnailUrl)
                    }
                }
            }
            self.scenesTableView.reloadData()
            }, failure: { errorMessage in
                if self.scenes?.count == 0 {
                    Drop.down("Failed to list scenes from the network", state: .Error, duration: 3)
                }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    func tableView(tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        let allRowCount = 1
        return self.scenes!.count + allRowCount;
        
    }
    
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = scenesTableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SceneTableViewCell
        
        
        if indexPath.row == 0 {
            // for first row, show "All"
            cell.sceneNameLabel?.text = "All"
        } else {
            // since first row is reserved for "All", indexPath becomes 1-indexed instead of 0-indexed
            let sceneIndex = indexPath.row - 1
            let scene = self.scenes![sceneIndex]
            
            cell.sceneNameLabel?.text = scene.name
            if let url = NSURL(string: scene.thumbnailUrl) {
                cell.sceneImageView.hnk_setImageFromURL(url)
            }
        }

        return cell
    }
 
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "sceneToEditor") {
            let indexPath = scenesTableView.indexPathForCell(sender as! UITableViewCell)!

            if indexPath.row != 0 {
                let sceneIndex = indexPath.row - 1
                let scene = self.scenes![sceneIndex]
                self.selectedScene = scene
            }
            

        }
    }
  
    
    
}
