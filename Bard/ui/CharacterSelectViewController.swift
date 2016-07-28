//
//  CharacterSelectViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-26.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import RealmSwift

class CharacterSelectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var charactersTableView: UITableView!
    var characters: Results<Character>? = nil
    let cellIdentifier = "CharacterTableViewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initCharacters()
        charactersTableView.delegate = self
        charactersTableView.dataSource = self
        
        syncRemoteData()
    }
    
    func initCharacters() {
        self.characters = try! Realm().objects(Character.self)
                                      .sorted("createdAt", ascending: false)
    }
    
    func syncRemoteData() {
        BardClient.getCharacterList(success: { value in
            for characterValues in value as? NSArray {
                Character.create(characterValues)
            }
        }, failure: { errorMessage in
                
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


}
