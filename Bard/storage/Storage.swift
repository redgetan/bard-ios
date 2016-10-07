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
    
    static func requestPhotoAccess() {
        if (PHPhotoLibrary.authorizationStatus() != .NotDetermined) {
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            //            switch status {
            //            case .Authorized:
            //            case .Denied:
            //            default:
            //                break
            //            }
        }
        
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
        if let username = UserConfig.getUsername() {
            return "\(documentDirectory)/\(username)/repositories"
        } else {
            return "\(documentDirectory)/anonymous/repositories"
        }
    }
    
    static func getSegmentsStorageDirectory() -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        return "\(documentDirectory)/segments"
    }
    
    static func getMergeVideoFilePath() -> String {
        let directoryPath = getRepositoryStorageDirectory()
        let fileName = "result.mp4"
        let path = (directoryPath as NSString).stringByAppendingPathComponent(fileName)
        return path
    }
    
    static func getRepositorySaveFilePath(characterName: String, text: String) -> String {
        let directoryPath = getRepositoryStorageDirectory()
        let date =  lround(NSDate().timeIntervalSince1970)
        let fileName = "\(characterName) says - \(text) [Bard] \(date).mp4"
        let path = (directoryPath as NSString).stringByAppendingPathComponent(fileName)
        return path
    }
    
    static func getRepositoryS3Key(characterName: String, uuid: String) -> String {
        if let username = UserConfig.getUsername() {
            return "repositories/\(username)/\(uuid).mp4"
        } else {
            return "repositories/anonymous/\(uuid).mp4"
        }
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
    
    static func saveRemoteVideo(urlString: String) -> String {
        
        // get download path and check if already downloaded
        let filePath = getSegmentFilePathFromUrl(urlString)
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            return filePath
        }
        
        
        let url = NSURL(string: urlString)!
        print("saving - \(url.path)")
        guard let urlData = NSData(contentsOfURL: url) else {
            return filePath
        }
        
        urlData.writeToFile(filePath, atomically: true)
        print("finished writing - \(url.path)")
        
        return filePath
    }
    
    static func saveRemoteVideoAsync(urlString: String,
                                activityIndicator: UIActivityIndicatorView? = nil,
                                completion: (String -> Void)? = nil) {

        activityIndicator?.startAnimating()

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            let filePath = saveRemoteVideo(urlString)
            
            dispatch_async(dispatch_get_main_queue()) {
                activityIndicator?.stopAnimating()
                completion?(filePath)
            }
        }
        
    }
    
    static func getSegmentFilePathFromUrl(urlString: String) -> String {
         let segmentsDirectory = getSegmentsStorageDirectory()
        
        let url = NSURL(string: urlString)!
        return "\(segmentsDirectory)/\(url.pathComponents!.last!)"
    }

    
}



