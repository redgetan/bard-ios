//
//  Character.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-27.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class Character: Object, Mappable {
    dynamic var token: String = ""
    dynamic var name: String = ""
    dynamic var details: String = ""
    dynamic var createdAt: NSDate = NSDate()
    
    required convenience init?(_ map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        token <- map["token"]
        name <- map["name"]
        details <- map["description"]
    }
}
