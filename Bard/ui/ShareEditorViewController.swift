//
//  ShareEditorViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-09-24.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import Social
import Player
import Photos
import SwiftyDrop
import AWSS3
import EZLoadingActivity

class ShareEditorViewController: UIViewController, PlayerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, FBSDKSharingDelegate {

    
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var socialShareCollectionView: UICollectionView!
    let cellIdentifier = "socialShareCollectionViewCell"
    
    var outputURL: NSURL!
    var outputWordTagStrings: [String] = [String]()
    var outputPhrase: String = ""
    var character: Character!
    var characterToken: String!
    var player: Player!
    var playButton: UIButton!
    var socialShares: [[String]] = [[String]]()
    var uuid: String? = nil
    var url: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        UIApplication.sharedApplication().statusBarStyle = .LightContent

        self.characterToken = character.token
        self.initPlayer()
        self.initSocialShare()
        
        playVideo(outputURL)
    }

    func playVideo(fileUrl: NSURL) {
        self.playButton.hidden = true

        self.player.setUrl(fileUrl)
        self.player.playFromBeginning()
    }
    
    @IBAction func shareRepo(sender: UIButton) {
        
        let objectsToShare = [outputURL]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func saveRepo(sender: UIButton) {
        if self.url != nil {
            // already saved
            self.saveButton.setTitle("Saved", forState: .Normal)
            self.saveButton.enabled = false
            self.performSelector(#selector(self.goToRootViewController), withObject: nil, afterDelay: 0.5)
        } else {
            EZLoadingActivity.show("Saving..", disableUI: true)
            uploadAndSaveToDisk({ url in
                if url != nil {
                    // successful
                    self.saveButton.setTitle("Saved", forState: .Normal)
                    self.saveButton.enabled = false
                    self.performSelector(#selector(self.goToRootViewController), withObject: nil, afterDelay: 0.5)
                }
                EZLoadingActivity.hide()
            })
        }
     
    }
    
    func saveRepoWithRemoteUrl(url: String, token: String, finished: (Int -> Void)? = nil) {
        let repoFilePath = Storage.getRepositorySaveFilePath(self.character.name, text: outputPhrase)
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.copyItemAtPath(self.outputURL.path!, toPath: repoFilePath)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        
        let username = UserConfig.getUsername() != nil ? UserConfig.getUsername()! : ""
        Repository.create(token,
                          wordTagStrings: self.outputWordTagStrings,
                          url: url,
                          username: username,
                          fileName: NSURL(fileURLWithPath: repoFilePath).pathComponents!.last!,
                          localIdentifier: nil,
                          characterToken: self.characterToken,
                          repoCreated: { repoId in
                            finished?(repoId)
        })
    }
    
    func goToRootViewController() {
       self.view.window!.rootViewController!.dismissViewControllerAnimated(false, completion: {})
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initSocialShare() {
        self.socialShares = [
            ["messenger","icon_messenger"],
            ["whatsapp", "icon_whatsapp"],
            ["kik", "icon_kik"],
            ["facebook", "icon_facebook"],
            ["twitter", "icon_twitter"],
            ["tumblr", "icon_tumblr"],
        ]
        
        socialShareCollectionView.contentInset = UIEdgeInsetsMake(30.0,40.0,0.0,40.0)
        socialShareCollectionView.delegate = self
        socialShareCollectionView.dataSource = self
    }
    
    func initPlayer() {
        self.player = self.childViewControllers.last as! Player
        self.player.delegate = self
        self.player.view.layer.hidden = false
        self.player.view.backgroundColor = UIColor.blackColor()
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.player.view.addGestureRecognizer(tapGestureRecognizer)
        
        // play button
        let button = UIButton()
        let image = UIImage(named: "icon_play_android")?.imageWithRenderingMode(.AlwaysTemplate)
        button.setImage(image, forState: .Normal)
        button.tintColor = UIColor.whiteColor()
        button.addTarget(self, action: #selector(onPlayBtnClick), forControlEvents: .TouchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.hidden = true
        self.playButton = button

        self.player.view.addSubview(button)

        
        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 100).active = true
        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 100).active = true
        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0).active = true

    }
    
    func onPlayBtnClick() {
        playVideo(outputURL)
    }
    
    // MARK: UIGestureRecognizer
    
    func handleTapGestureRecognizer(gestureRecognizer: UITapGestureRecognizer) {
        switch (self.player.playbackState.rawValue) {
        case PlaybackState.Stopped.rawValue:
            self.playButton.hidden = true
            self.player.playFromBeginning()
        case PlaybackState.Paused.rawValue:
            self.player.playFromCurrentTime()
        case PlaybackState.Playing.rawValue:
            self.player.pause()
        case PlaybackState.Failed.rawValue:
            self.player.pause()
        default:
            self.player.pause()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
//        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default
    }
    
    // MARK: PlayerDelegate
    
    func playerReady(player: Player) {
    }
    
    func playerPlaybackStateDidChange(player: Player) {
    }
    
    func playerBufferingStateDidChange(player: Player) {
    }
    
    func playerPlaybackWillStartFromBeginning(player: Player) {
    }
    
    func playerPlaybackDidEnd(player: Player) {
        self.playButton.hidden = false
    }
    
    func playerCurrentTimeDidChange(player: Player) {
    }
    

    // MARK: UICollectionViewDataSource protocol
    
    func collectionView(collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return 6
        
    }
    
    // MARK: UICollectionViewDelegate protocol
    
    func collectionView(collectionView: UICollectionView,
                        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let socialShare = self.socialShares[indexPath.row]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier,
                                                                         forIndexPath: indexPath) as!SocialShareCollectionViewCell

        cell.imageView?.image = UIImage(named: socialShare[1])
        cell.label?.text = socialShare[0]
        
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .NotDetermined {
            Storage.requestPhotoAccess()
        } else if status == .Authorized {
            onSocialShareClick(indexPath.row)
        } else {
            Drop.down("Please allow Photo Access to enable Facebook share", state: .Error, duration: 4)
        }
        
    }
    
    func onSocialShareClick(index: Int) {
        let socialShare = self.socialShares[index]
        
        if socialShare[0] == "facebook" {
            facebookDirectShare()
        } else if socialShare[0] == "messenger" {
            let videoData = NSData(contentsOfFile: outputURL.path!)
            FBSDKMessengerSharer.shareVideo(videoData, withOptions:nil)
        } else if socialShare[0] == "twitter" {
            if self.url != nil {
                // already uploaded this repo to bard with generated url
                self.doTwitterShare(self.url!)
            } else {
                EZLoadingActivity.show("Uploading video", disableUI: true)
                uploadAndSaveToDisk({ url in
                    if url != nil {
                        // upload success
                        self.url = url
                        self.doTwitterShare(url!)
                    }
                    EZLoadingActivity.hide()
                })
            }
            
        } else {
            shareRepo(UIButton())
        }
    }
    
    func uploadAndSaveToDisk(handler: (String? -> Void)? = nil) {
        uploadFileToS3({ uuid in
            if uuid == nil {
                // error upload
                dispatch_async(dispatch_get_main_queue()) {
                    Drop.down("Unable to upload video", state: .Error, duration: 3)
                }
                handler?(nil)
            } else {
                // success upload
                
                // create Repository both locally and remotely, get link of repo
                BardClient.postRepo(uuid!,
                    characterToken: self.characterToken,
                    wordList: self.outputWordTagStrings.joinWithSeparator(","),
                    success: { result in
                        let dict = (result as! [String:AnyObject])

                        if let remoteUrl = dict["url"] as? String {
                            let token = dict["token"] as! String
                            self.saveRepoWithRemoteUrl(remoteUrl, token: token, finished: { repoId in
                                handler?(remoteUrl)
                            })
                        }
                    }, failure: { error in
                        dispatch_async(dispatch_get_main_queue()) {
                            Drop.down("Unable to sync video to servers", state: .Error, duration: 3)
                        }
                        handler?(nil)
                })
                
            }
        })

    }
    
    func doTwitterShare(url: String) {
        if let vc = SLComposeViewController(forServiceType: SLServiceTypeTwitter) {
            vc.setInitialText("I made \(character.name) say \(url) via @letsbard")
            presentViewController(vc, animated: true, completion: {})
        }
    }
    
    func uploadFileToS3(handler: (String? -> Void)? = nil ) {
        // check if File is Uploaded
        if self.uuid != nil {
            handler?(self.uuid)
        }
        
        let uuid = NSUUID().UUIDString.lowercaseString
        let s3Key = Storage.getRepositoryS3Key(self.character.name, uuid: uuid)
       
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        let testFileURL1 = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("temp")
        let uploadRequest1 : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
        
        let data = NSData(contentsOfFile: outputURL.path!)!
        data.writeToURL(testFileURL1!, atomically: true)
        uploadRequest1.bucket = Configuration.s3UserBucket
        uploadRequest1.key = s3Key
        uploadRequest1.body = testFileURL1
        
        let task = transferManager.upload(uploadRequest1)
        task.continueWithBlock { task in
            if task.error != nil {
                print("Error: \(task.error)")
                handler?(nil)
            } else {
                self.uuid = uuid
                print("Upload successful")
                handler?(uuid)
            }
            return nil
        }
    }


    func facebookDirectShare() {
        if !UIApplication.sharedApplication().canOpenURL(NSURL(string: "fbauth2://")!) {
            Drop.down("You must install Facebook first", state: .Error, duration: 2)
            return
        }
        
        Storage.copyFileToAlbum(localFileUrl: outputURL, handler: { localIdentifier in
            if localIdentifier != nil {
                // http://stackoverflow.com/a/34788748
                
                let assetID = localIdentifier!.stringByReplacingOccurrencesOfString(
                    "/.*", withString: "",
                    options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
                let ext = "mp4"
                let assetURLStr =
                    "assets-library://asset/asset.\(ext)?id=\(assetID)&ext=\(ext)"
                
                let localVideoUrl = NSURL(string: assetURLStr)!
                let video   = FBSDKShareVideo()
                video.videoURL = localVideoUrl
                
                let content = FBSDKShareVideoContent()
                content.video = video
                dispatch_async(dispatch_get_main_queue()) {
                    FBSDKShareDialog.showFromViewController(self, withContent: content, delegate: self)
                }
            }
        })
    }
    
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        print("success ")

    }
    
    /*!
     @abstract Sent to the delegate when the sharer encounters an error.
     @param sharer The FBSDKSharing that completed.
     @param error The error.
     */
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        print("error \(error)")
    
    }
    
    func sharerDidCancel(sharer: FBSDKSharing!) {
        print("cancel ")

    }

    
    // MARK: UICollectionViewDelegateFlowLayout protocol
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
//        let totalHeight: CGFloat = (self.view.frame.width / 3)
//        let totalWidth: CGFloat = (self.view.frame.width / 3)
        
        let screenRect = UIScreen.mainScreen().bounds
        let screenWidth = screenRect.size.width
        
        // 100 represents the padding we added to socialShareCollectionView
        let totalWidth = (screenWidth - 80) / 3.0
        let totalHeight = CGFloat(80.0)
        
        return CGSizeMake(totalWidth, totalHeight)
    }

    

}
