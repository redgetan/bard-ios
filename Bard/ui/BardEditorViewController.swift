//
//  BardEditorViewController.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-27.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit
import RealmSwift
import Player
import Photos
import SwiftyDrop


class BardEditorViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    let cdnPath = "https://d22z4oll34c07f.cloudfront.net"
    var characterToken = ""
    var sceneToken = ""
    var wordTagMap: [String: [String]] = [String: [String]]()
    var wordTagStringList: [String] = [String]()
    var player: Player!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var wordTagCollectionView: UICollectionView!
    let cellIdentifier = "wordTagCollectionViewCell"
    let words = ["this","is","sparta","300","everyone","speaks","english","funny","spadina","bathurst","station","is","coming"]
    let sizingCell: WordTagCollectionViewCell = WordTagCollectionViewCell()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // http://stackoverflow.com/a/16570399/803865
//        wordTagCollectionView.backgroundView!.backgroundColor = UIColor.clearColor()
        wordTagCollectionView.contentInset=UIEdgeInsetsMake(20.0,20.0,20.0,20.0);
        wordTagCollectionView.delegate = self
        wordTagCollectionView.dataSource = self
        initPlayer()
        initDictionary()
        initCollectionViewCell()
    }
    
    func initCollectionViewCell() {
        wordTagCollectionView.registerClass(WordTagCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
    }
    
    
    // MARK: UICollectionViewDataSource protocol
    
    func collectionView(collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return self.wordTagStringList.count
    }
    
    // MARK: UICollectionViewDelegate protocol
    
    func collectionView(collectionView: UICollectionView,
                                 cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier,
        forIndexPath: indexPath) as! WordTagCollectionViewCell

        let wordTagString = self.wordTagStringList[indexPath.row]
        let word = wordTagString.componentsSeparatedByString(":")[0]

        cell.textLabel.text = word
        cell.wordTagString = wordTagString

        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let wordTagString = self.wordTagStringList[indexPath.row]
        let word = wordTagString.componentsSeparatedByString(":")[0]
        self.sizingCell.textLabel.text = word;
        return self.sizingCell.intrinsicContentSize()
    }

    
    @IBAction func onPlayBtnClick(sender: UIButton) {
        generateBardVideo()
    }
    
    func generateBardVideo() {
        guard let text = inputTextField.text else {
            print("text is blank. type something")
            return
        }
        
        let wordTagStrings = getWordTagStrings(text)
        let segmentUrls = wordTagStrings.map { wordTagString in
            segmentUrlFromWordTag(wordTagString)
            }.flatMap { $0 }
        
        fetchSegments(segmentUrls, completion: { filePaths in
            VideoMerger.mergeMultipleVideos(filePaths, finished: { outputURL, localIdentifier in
                Repository.create(wordTagStrings, fileName: outputURL.pathComponents!.last!, localIdentifier: localIdentifier)
                self.playVideo(outputURL)
            })
        })

    }
    
    // http://stackoverflow.com/a/11909880/803865
    
    func fetchSegments(segmentUrls: [String], completion: ([String] -> Void)? = nil ) {
        let group = dispatch_group_create()
        
        for segmentUrl in segmentUrls {
            dispatch_group_async(group, dispatch_get_main_queue(), {
                Storage.saveRemoteVideo(segmentUrl)
            })
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(),{
            var filePaths = [String]()
            
            for segmentUrl in segmentUrls {
                let filePath = Storage.getDownloadFilePathFromUrl(segmentUrl)
                if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                    filePaths.append(filePath)
                }
            }
            
            completion?(filePaths)
            
        });
        
    }

    
    func getWordTagStrings(text: String) -> [String] {
        var wordTagStrings = [String]()
        
        for word in text.componentsSeparatedByString(" ") {
            guard let wordTagString = randomWordTagFromWord(word) else {
                print("missing word \(word)")
                continue
            }
            
            wordTagStrings.append(wordTagString)
        }
        
        return wordTagStrings
    }
    
    func getSceneFromWordTag(wordTagString: String) -> Scene? {
        return try! Realm().objects(Scene.self).filter("wordList CONTAINS '\(wordTagString)'").first
    }
    
    func segmentUrlFromWordTag(wordTagString: String) -> String? {
        guard let scene = getSceneFromWordTag(wordTagString) else {
            return nil
        }
        
        let tag = wordTagString.componentsSeparatedByString(":")[1]
        
        return "\(cdnPath)/segments/\(scene.token)/\(tag).mp4"
        
    }
    
    func randomWordTagFromWord(word: String) -> String? {
        guard let wordTagList = self.wordTagMap[word] else {
            return nil
        }
        
        let randomIndex = Int(arc4random_uniform(UInt32(wordTagList.count)))
        return wordTagList[randomIndex]
    }


    
    func getScenes() -> Results<Scene> {
        if !sceneToken.isEmpty {
            return try! Realm().objects(Scene.self).filter("token = '\(sceneToken)'")
        } else {
            return try! Realm().objects(Scene.self).filter("characterToken = '\(characterToken)'")
        }
    }
    
    func initDictionary() {
        for scene in getScenes() {
            if let wordList = scene.wordList {
                addWordListToDictionary(wordList)
            } else {
                BardClient.getSceneWordList(characterToken, sceneToken: sceneToken, success: { value in
                    if let sceneWordList = value["wordList"] as? String {
                        let realm = try! Realm()
                        try! realm.write {
                            scene.wordList = sceneWordList
                        }
                        
                        self.addWordListToDictionary(sceneWordList)
                    }

                }, failure: { errorMessage in
                    Drop.down("Failed to load word list", state: .Error, duration: 3)
                })
            }
        }
    }
    
    func addWordListToDictionary(wordList: String) {
        var word: String

        for wordTagString in wordList.componentsSeparatedByString(",") {
            wordTagStringList.append(wordTagString)
            word = wordTagString.componentsSeparatedByString(":")[0]
            
            if wordTagMap[word] != nil {
                wordTagMap[word]!.append(wordTagString)
            } else {
                wordTagMap[word] = [String]()
                wordTagMap[word]!.append(wordTagString)
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initPlayer() {
        self.player = self.childViewControllers.last as! Player
        self.player.view.layer.hidden = false
        self.player.view.backgroundColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1.0)
        
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.player.view.addGestureRecognizer(tapGestureRecognizer)
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