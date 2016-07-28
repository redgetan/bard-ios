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
    dynamic var token: String = ""
    dynamic var url: String = ""
    dynamic var fileName: String = ""
    dynamic var localIdentifier: String? = ""
    dynamic var isPublished: Bool = false
    dynamic var wordList: String = ""
    dynamic var createdAt: NSDate = NSDate()
    
    static func create(wordTagStrings: [String], fileName: String, localIdentifier: String?) {
        let repository = Repository()
        repository.wordList = wordTagStrings.joinWithSeparator(",")
        repository.fileName = fileName
        repository.localIdentifier = localIdentifier
        repository.createdAt = NSDate()
        
        let realm = try! Realm()
        try! realm.write {
            realm.add(repository)
        }

    }
    
    override static func primaryKey() -> String? {
        return "token"
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