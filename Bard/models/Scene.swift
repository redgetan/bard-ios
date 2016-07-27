//
//  Scene.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-27.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class Scene: Object, Mappable {
    dynamic var name: String = ""
    dynamic var token: String = ""
    dynamic var characterToken: String = ""
    dynamic var wordList: String = ""
    dynamic var thumbnailUrl: String = ""
    dynamic var createdAt: NSDate = NSDate()

    
    required convenience init?(_ map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        name <- map["name"]
        token <- map["videoToken"]
        characterToken <- map["bundleToken"]
        thumbnailUrl <- map["thumbnailUrl"]
        wordList <- map["wordList"]
    }
}