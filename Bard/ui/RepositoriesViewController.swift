//
//  FirstViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-24.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import RealmSwift

class RepositoriesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var upperPanel: UIView!
    @IBOutlet weak var repositoriesTableView: UITableView!
    var repositories: Results<Repository>? = nil
    let cellIdentifier = "RepositoryTableViewCell"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Helper.addBorder(upperPanel, edges: [.Bottom], colour: UIColor(hex: "#CCCCCC"))
        
        initRepositories()
        repositoriesTableView.delegate = self
        repositoriesTableView.dataSource = self
    }
    
    func initRepositories() {
        self.repositories = try! Realm().objects(Repository.self).sorted("createdAt", ascending: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return self.repositories!.count;
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



}

