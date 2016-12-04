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
    dynamic var wordList: String = ""
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
        let dict = (obj as! [String:AnyObject])

        scene.name = dict["name"] as! String
        scene.token = dict["token"] as! String
        scene.thumbnailUrl = dict["thumbnailUrl"] as! String
        scene.wordList = dict["wordList"] as? String ?? ""
        
        let realm = try! Realm()
        
        if realm.objects(Scene.self).filter("token = '\(scene.token)'").first != nil {
            return
        }
        
        try! realm.write {
            realm.add(scene)
        }
    }
    
    static func createWithTokenAndName(obj: AnyObject) {
        let scene = Scene()
        let dict = (obj as! [String:AnyObject])
        
        scene.name = dict["name"] as! String
        scene.token = dict["token"] as! String
        scene.thumbnailUrl = dict["thumbnailUrl"] as! String
        
        let realm = try! Realm()
        
        if realm.objects(Scene.self).filter("token = '\(scene.token)'").first != nil {
            return
        }
        
        try! realm.write {
            realm.add(scene)
        }
    }
    
    func setNameAndThumbnail(name: String, thumbnailUrl: String) {
        let realm = try! Realm()
        
        try! realm.write {
            self.name = name
            self.thumbnailUrl = thumbnailUrl
        }
    }
    
    static func createWithTokenAndWordList(sceneToken: String, characterToken: String, wordList: String) {
        let scene = Scene()
        scene.token = sceneToken
        scene.characterToken = characterToken
        scene.wordList = wordList
        
        let realm = try! Realm()
        
        if realm.objects(Scene.self).filter("token = '\(scene.token)'").first != nil {
            return
        }
        
        try! realm.write {
            realm.add(scene)
        }
    }
    
    static func forToken(token: String) -> Scene? {
        return try! Realm().objects(Scene.self).filter("token = '\(token)'").first
    }
    
    static func forCharacterToken(characterToken: String) -> Results<Scene> {
        return try! Realm().objects(Scene.self).filter("characterToken = '\(characterToken)'")
    }
    
    override static func primaryKey() -> String? {
        return "token"
    }
    
    
    
}
