//
//  ShareEditorViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-09-24.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import Player

class ShareEditorViewController: UIViewController {

    
    @IBOutlet weak var header: UIView!
    
    var outputURL: NSURL!
    var player: Player!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initPlayer()
        
//        let view: UIView = UIView(frame: CGRectMake(0.0, 0.0, 320.0, 50.0))
//        let gradient: CAGradientLayer = CAGradientLayer()
//        gradient.frame = header.bounds
//        gradient.colors = [UIColor.clearColor().CGColor,UIColor.blackColor().CGColor]
//        header.layer.mask = gradient

//        playVideo(NSURL(string: "https://d22z4oll34c07f.cloudfront.net/segments/F6nNlIbgWTU/8435.mp4")!)
        playVideo(outputURL)
    }

    func playVideo(fileUrl: NSURL) {
        self.player.setUrl(fileUrl)
        self.player.playFromBeginning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initPlayer() {
        self.player = self.childViewControllers.last as! Player
        self.player.view.layer.hidden = false
        self.player.view.backgroundColor = UIColor.blackColor()
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.player.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: UIGestureRecognizer
    
    func handleTapGestureRecognizer(gestureRecognizer: UITapGestureRecognizer) {
        switch (self.player.playbackState.rawValue) {
        case PlaybackState.Stopped.rawValue:
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
    }
    
    func playerCurrentTimeDidChange(player: Player) {
    }
    


    

}
