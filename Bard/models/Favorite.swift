//
//  Favorite.swift
//  Bard
//
//  Created by Reginald Tan on 2017-03-24.
//  Copyright © 2017 ROP Labs. All rights reserved.
//

import Foundation

import RealmSwift

class Favorite: Object {
    dynamic var username: String = ""
    dynamic var sceneToken: String = ""
    dynamic var createdAt: NSDate = NSDate()
    
    static var count: Int {
        get {
            let realm = try! Realm()
            return realm.objects(Favorite.self).count
        }
    }
    
    static func create(username: String, sceneToken: String) {
        let favorite = Favorite()
        let dict = (obj as! [String:AnyObject])
        
        favorite.username = username
        favorite.sceneToken = sceneToken
        
        let realm = try! Realm()
        
        if realm.objects(Favorite.self)
                .filter("sceneToken = '\(favorite.sceneToken)' AND username = \(favorite.username)")
                .first != nil {
            return
        }
        
        try! realm.write {
            realm.add(favorite)
        }
    }
    
    
    static func forUsername(username: String) -> Results<Favorite> {
        return try! Realm().objects(Favorite.self).filter("username = '\(username)'").sorted("createdAt", ascending: false)
    }
    
    
    
    
}
