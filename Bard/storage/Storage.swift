//
//  Storage.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-27.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation
import Photos


class Storage {
    
    static func setup() {
//        createAlbumIfNotPresent()
        createMissingDirectories()
    }
    
    static func createMissingDirectories() {
        createStorageDirectory(getRepositoryStorageDirectory())
        createStorageDirectory(getSegmentsStorageDirectory())
    }
    
    static func createStorageDirectory(directoryPath: String) {
        if NSFileManager.defaultManager().fileExistsAtPath(directoryPath) {
            return
        }
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
    }
    
    
    static func getRepositoryStorageDirectory() -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let directoryPath = "\(documentDirectory)/\(UserConfig.getUsername())/repositories"
        return directoryPath
    }
    
    static func getSegmentsStorageDirectory() -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let directoryPath = "\(documentDirectory)/\(UserConfig.getUsername())/segments"
        return directoryPath
    }
    
    static func getMergeVideoFilePath(characterName: String, text: String) -> String {
        let directoryPath = getRepositoryStorageDirectory()
        let date =  lround(NSDate().timeIntervalSince1970)
        let fileName = "\(characterName) says - \(text) [Bard] \(date).mp4"
        let path = (directoryPath as NSString).stringByAppendingPathComponent(fileName)
        return path
    }
    
    // MARK: Album Helpers
    
    static let ALBUM_NAME = "Bard"
    
    static func isAlbumExists(albumName: String) -> Bool {
        return getAlbumResult(albumName).count > 0
    }
    
    static func getAlbumResult(albumName: String) -> PHFetchResult {
        // https://github.com/zakkhoyt/PHAsset-Utility/blob/master/PHAsset%2BUtility.m
        
        let predicate = NSPredicate(format: "localizedTitle = %@", albumName)
        let options = PHFetchOptions()
        options.predicate = predicate
        return PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: options)
    }
    
    static func createAlbumIfNotPresent() {
        guard !isAlbumExists(ALBUM_NAME) else {
            return
        }
        
        NSLog("\nFolder \"%@\" does not exist\nCreating now...", ALBUM_NAME)
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(ALBUM_NAME)
            },completionHandler: { success, error in
                
        })
        
    }
    
    
    static func copyFileToAlbum(localFileUrl filePathUrl: NSURL, handler: (String? -> Void)? = nil ) {
        var assetPlaceholder: PHObjectPlaceholder = PHObjectPlaceholder()
    
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            // asset
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(filePathUrl)
            assetPlaceholder = createAssetRequest!.placeholderForCreatedAsset!
            
            // album
            let albumResult = getAlbumResult(ALBUM_NAME)
            let albumAssetCollection = albumResult.firstObject as! PHAssetCollection
            
            // add asset to album
            let albumChangeRequest = PHAssetCollectionChangeRequest(
                forAssetCollection: albumAssetCollection,
                assets: albumResult)
            albumChangeRequest!.addAssets([assetPlaceholder])
            
        }) { completed, error in
            if completed {
                print("File copied to album")
                handler?(assetPlaceholder.localIdentifier)
            } else if error != nil {
                handler?(nil)
            }
        }
        
    }
    
    static func removeFile(path: String) {
        let fileManager = NSFileManager.defaultManager()
        
        do {
            try fileManager.removeItemAtPath(path)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }
    
    
    // MARK: remote video persistence
    
    static func saveRemoteVideo(urlString: String) -> String? {

        // get download path and check if already downloaded
        let filePath = getSegmentFilePathFromUrl(urlString)
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            return nil
        }

        
        let url = NSURL(string: urlString)!
        print("saving - \(url.path)")
        guard let urlData = NSData(contentsOfURL: url) else {
            return nil
        }
        
        urlData.writeToFile(filePath, atomically: true)
        print("finished writing - \(url.path)")
        
        return filePath
    }
    
    static func getSegmentFilePathFromUrl(urlString: String) -> String {
         let segmentsDirectory = getSegmentsStorageDirectory()
        
        let url = NSURL(string: urlString)!
        return "\(segmentsDirectory)/\(url.pathComponents!.last!)"
    }

    
}



