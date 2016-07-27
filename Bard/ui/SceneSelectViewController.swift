//
//  CharacterSelectViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-26.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import RealmSwift

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
    }
    
    func initScenes() {
        self.scenes = try! Realm().objects(Scene.self)
            .filter("characterToken = '\(characterToken)'")
            .sorted("createdAt", ascending: false)
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
        
        let cell = scenesTableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = scene.name
        return cell;
    }
    
    
}
