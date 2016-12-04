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
    
    var scenes: [Scene] = []
    var selectedScene: Scene? = nil
    let cellIdentifier = "SceneTableViewCell"
    var character: Character!
    var totalRowsLoaded: Int = 0
    var totalPagesLoaded: Int = 0
    var isLoading: Bool = false
    var isEndOfPage: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backButton
        
        initScenes()
        scenesTableView.delegate = self
        scenesTableView.dataSource = self
        
        syncRemoteData(self.totalPagesLoaded + 1)
    }
    
    func initScenes() {
        self.scenes = []
    }
    
    func syncRemoteData(pageIndex: Int) {
        var sceneToken: String = ""
        var thumbnailUrl: String = ""
        var sceneName: String = ""
        var scene: Scene?
        
        BardClient.getSceneList(pageIndex, success: { value in
            for obj in (value as! NSArray) {
                let dict = (obj as! [String:AnyObject])

                sceneToken = dict["token"] as! String
                thumbnailUrl = dict["thumbnailUrl"] as! String
                sceneName = dict["name"] as! String
                
                scene = Scene.forToken(sceneToken)
                
                if scene == nil {
                     // create scene if it didnt exist before
                    scene = Scene.createWithTokenAndName(dict)
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
            }, failure: { errorMessage in
                if self.scenes.count == 0 {
                    Drop.down("Failed to list scenes from the network", state: .Error, duration: 3)
                }
        })
    }
    
    func getScenesNextPage() {
        syncRemoteData(self.totalPagesLoaded + 1)
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
        if let url = NSURL(string: scene.thumbnailUrl) {
            cell.sceneImageView.hnk_setImageFromURL(url)
        }
    

        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if (indexPath.row + 1  >= self.totalRowsLoaded && !isLoading && !isEndOfPage) {
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

            if indexPath.row != 0 {
                let sceneIndex = indexPath.row
                let scene = self.scenes[sceneIndex]
                Analytics.track("compose", properties: ["sceneToken" : scene.token,
                    "scene" : scene.name])
                BardLogger.log("sceneSelect: \(scene.name) - \(scene.token)")
                let viewController = segue.destinationViewController as! BardEditorViewController;
                viewController.scene = scene

            }
            

        }
    }
  
    
    
}
