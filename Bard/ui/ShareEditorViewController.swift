//
//  ShareEditorViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-09-24.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import Player

class ShareEditorViewController: UIViewController, PlayerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    
    @IBOutlet weak var header: UIView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var socialShareCollectionView: UICollectionView!
    let cellIdentifier = "socialShareCollectionViewCell"
    
    var outputURL: NSURL!
    var outputWordTagStrings: [String] = [String]()
    var outputPhrase: String = ""
    var character: Character!
    var player: Player!
    var playButton: UIButton!
    var socialShares: [[String]] = [[String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        UIApplication.sharedApplication().statusBarStyle = .LightContent
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
        let repoFilePath = Storage.getRepositorySaveFilePath(self.character.name, text: outputPhrase)
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.copyItemAtPath(self.outputURL.path!, toPath: repoFilePath)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        
        Repository.create(self.outputWordTagStrings,
            username: UserConfig.getUsername(),
            fileName: NSURL(fileURLWithPath: repoFilePath).pathComponents!.last!,
            localIdentifier: nil,
            characterToken: self.character.token,
            repoCreated: { repoId in
                self.saveButton.setTitle("Saved", forState: .Normal)
                self.saveButton.enabled = false
                self.performSelector(#selector(self.goToRootViewController), withObject: nil, afterDelay: 0.5)
        })
    }
    
    func goToRootViewController() {
        self.view.window!.rootViewController!.dismissViewControllerAnimated(true, completion: {})
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
        
        socialShareCollectionView.contentInset = UIEdgeInsetsMake(0.0,0.0,0.0,0.0)
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
        let totalWidth = screenWidth / 3.0
        
        return CGSizeMake(totalWidth, totalWidth)
    }

    

}
