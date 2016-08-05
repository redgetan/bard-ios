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
    
    static func create(obj: AnyObject) -> Void {
        let character = Character()
        
        character.name = obj["name"] as! String
        character.token = obj["token"] as! String
        character.details = obj["description"] as? String
        
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
