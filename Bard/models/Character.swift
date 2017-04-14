//
//  Character.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-27.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import RealmSwift

class Pack: Object {
    dynamic var token: String = ""
    dynamic var name: String = ""
    dynamic var details: String? = ""
    dynamic var isBundleDownloaded: Bool = false
    dynamic var createdAt: NSDate = NSDate()
    
    static var count: Int {
        get {
            let realm = try! Realm()
            return realm.objects(Pack.self).count
        }
    }
    
    static func forToken(token: String) -> Pack? {
        return try! Realm().objects(Pack.self).filter("token = '\(token)'").first
    }
    
    static func create(obj: AnyObject) -> Void {
        let pack = Pack()
        let dict = (obj as! [String:AnyObject])
        pack.name = dict["name"] as! String
        pack.token = dict["token"] as! String
        pack.details = dict["description"] as? String
        
        let realm = try! Realm()

        if realm.objects(Pack.self).filter("token = '\(pack.token)'").first != nil {
            return
        }
        
        try! realm.write {
            realm.add(pack)
        }
        
    }
    
    override static func primaryKey() -> String? {
        return "token"
    }
    

}
