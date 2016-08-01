//
//  VideoPlayerViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-08-01.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import Player

class VideoPlayerViewController: UIViewController {
    var repository: Repository!
    var player: Player!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = repository.details()
        initPlayer()
        playVideo(repository.getFileUrl())
    }
    
    func initPlayer() {
        self.player = self.childViewControllers.last as! Player
        self.player.view.layer.hidden = false
        self.player.view.backgroundColor = UIColor.blackColor()
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.player.view.addGestureRecognizer(tapGestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func playVideo(fileUrl: NSURL) {
        self.player.setUrl(fileUrl)
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
