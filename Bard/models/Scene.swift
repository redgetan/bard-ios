//
//  Scene.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-27.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import RealmSwift

class Scene: Object {
    dynamic var name: String = ""
    dynamic var token: String = ""
    dynamic var characterToken: String = ""
    dynamic var wordList: String? = ""
    dynamic var thumbnailUrl: String = ""
    dynamic var createdAt: NSDate = NSDate()
    
    static var count: Int {
        get {
            let realm = try! Realm()
            return realm.objects(Scene.self).count
        }
    }

    static func create(obj: AnyObject) {
        let scene = Scene()
        scene.name = obj["name"] as! String
        scene.token = obj["videoToken"] as! String
        scene.characterToken = obj["bundleToken"] as! String
        scene.thumbnailUrl = obj["thumbnailUrl"] as! String
        scene.wordList = obj["wordList"] as? String
        
        let realm = try! Realm()
        
        if realm.objects(Scene.self).filter("token = '\(scene.token)'").first != nil {
            return
        }
        
        try! realm.write {
            realm.add(scene)
        }
    }
    
    override static func primaryKey() -> String? {
        return "token"
    }
    
    
    
}