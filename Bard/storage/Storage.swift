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
        createAlbumIfNotPresent()
        createMissingDirectories()
    }
    
    static func createMissingDirectories() {
        createStorageDirectory(getRepositoryStorageDirectory())
    }
    
    static func createStorageDirectory(directoryPath: String) {
        if NSFileManager.defaultManager().fileExistsAtPath(directoryPath) {
            return
        }
        
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(directoryPath, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
    }
    
    
    static func getRepositoryStorageDirectory() -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let directoryPath = (documentDirectory as NSString).stringByAppendingPathComponent("repositories")
        return directoryPath
    }
    
    static func getMergeVideoFilePath() -> String {
        let directoryPath = getRepositoryStorageDirectory()
        let date =  NSDate().timeIntervalSince1970
        let path = (directoryPath as NSString).stringByAppendingPathComponent("mergeVideo\(date).mp4")
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
        
        dispatch_async(dispatch_get_main_queue(), {
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
        })
        
    }
    
    // MARK: remote video persistence
    
    static func saveRemoteVideo(urlString: String) -> String? {
        let url = NSURL(string: urlString)!
        print("saving - \(url.path)")
        guard let urlData = NSData(contentsOfURL: url) else {
            return nil
        }
        
        let filePath = getDownloadFilePathFromUrl(urlString)
        urlData.writeToFile(filePath, atomically: true)
        print("finished writing - \(url.path)")
        
        return filePath
    }
    
    static func getDownloadFilePathFromUrl(urlString: String) -> String {
         let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        
        let url = NSURL(string: urlString)!
        return "\(documentDirectory)/\(url.pathComponents!.last!)"
    }

    
}



