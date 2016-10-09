//
//  Character.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-27.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import RealmSwift

class Character: Object {
    dynamic var token: String = ""
    dynamic var name: String = ""
    dynamic var details: String? = ""
    dynamic var isBundleDownloaded: Bool = false
    dynamic var createdAt: NSDate = NSDate()
    
    static var count: Int {
        get {
            let realm = try! Realm()
            return realm.objects(Character.self).count
        }
    }
    
    static func forToken(token: String) -> Character? {
        return try! Realm().objects(Character.self).filter("token = '\(token)'").first
    }
    
    static func create(obj: AnyObject) -> Void {
        let character = Character()
        let dict = (obj as! [String:AnyObject])
        character.name = dict["name"] as! String
        character.token = dict["token"] as! String
        character.details = dict["description"] as? String
        
        let realm = try! Realm()

        if realm.objects(Character.self).filter("token = '\(character.token)'").first != nil {
            return
        }
        
        try! realm.write {
            realm.add(character)
        }
        
    }
    
    override static func primaryKey() -> String? {
        return "token"
    }
    

}
