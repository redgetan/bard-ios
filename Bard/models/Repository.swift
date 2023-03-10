//
//  Repository.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-27.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import RealmSwift
import AVFoundation

class Repository: Object {
    dynamic var id: Int = 0
    dynamic var token: String = ""
    dynamic var username: String = ""
    dynamic var url: String = ""
    dynamic var fileName: String = ""
    dynamic var localIdentifier: String? = ""
    dynamic var isPublished: Bool = false
    dynamic var wordList: String = ""
    dynamic var characterToken: String = ""
    dynamic var sceneToken: String? = nil
    dynamic var createdAt: NSDate = NSDate()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func find(id: Int) -> Repository {
        let repo = try! Realm().objects(Repository.self).filter("id = \(id)").first!
        return repo
    }
    
    static func forUrl(url: String?) -> Repository? {
        if url == nil {
            return nil
        }
        
        return try! Realm().objects(Repository.self).filter("url = '\(url!)'").first
    }
    
    static func create(token: String, wordTagStrings: [String], url: String, username: String, fileName: String, localIdentifier: String?, sceneToken: String? = nil, repoCreated: (Int -> Void)? = nil) {

        let repository = Repository()
        repository.id = getNextId()
        repository.wordList = wordTagStrings.joinWithSeparator(",")
        repository.url = url
        repository.fileName = fileName
        repository.username = username
        repository.localIdentifier = localIdentifier
        repository.token = token
        repository.sceneToken = sceneToken
        repository.createdAt = NSDate()
                
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let realm = try! Realm()
           
            try! realm.write {
                realm.add(repository)
            }
            
            let id = repository.id
            dispatch_async(dispatch_get_main_queue()) {
                repoCreated?(id)
            }

        }
        
    }
    
    func delete() {
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(self)
        }
    }
    
    static func getNextId() -> Int {
        let realm = try! Realm()
        if let maxId: Int = realm.objects(Repository.self).max("id") {
            return maxId + 1
        } else {
            return 1
        }
    }
    
    func details() -> String {
        var result = [String]()
        var word: String
        
        for wordTagString in wordList.componentsSeparatedByString(",") {
            word = wordTagString.componentsSeparatedByString(":")[0]
            result.append(word)
        }
        
        return result.joinWithSeparator(" ")
    }
    
    func getFilePath() -> String {
        let directoryPath = Storage.getRepositoryStorageDirectory()
        return "\(directoryPath)/\(fileName)"
    }
    
    func getFileUrl() -> NSURL {
        return NSURL(fileURLWithPath: getFilePath())
    }
    
    func getToken() -> String {
        return token
    }
    
    func getUIImage() -> UIImage? {
        // http://stackoverflow.com/a/31779221/803865
        
        let asset = AVURLAsset(URL: NSURL(fileURLWithPath: getFilePath()), options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        do {
            let cgImage = try imgGenerator.copyCGImageAtTime(CMTimeMake(0, 1), actualTime: nil)
            return UIImage(CGImage: cgImage)
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
    }
    
    
    
}
