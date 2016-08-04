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
    var character: Character!
    var scene: Scene? = nil
    var wordTagMap: [String: [String]] = [String: [String]]()
    var wordTagStringList: [String] = [String]()
    var player: Player!
    var isKeyboardShown: Bool = false
    var activityIndicator: UIActivityIndicatorView? = nil
    var repositoryId: Int? = nil
    
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var wordTagCollectionView: UICollectionView!
    @IBOutlet weak var controlButton: UIButton!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    let cellIdentifier = "wordTagCollectionViewCell"
    let words = ["this","is","sparta","300","everyone","speaks","english","funny","spadina","bathurst","station","is","coming"]
    let sizingCell: WordTagCollectionViewCell = WordTagCollectionViewCell()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = scene?.name ?? character.name
        initPlayer()
        initDictionary()
        initCollectionView()
    }
    
    @IBAction func controlButtonClick(sender: UIButton) {
        if isKeyboardShown {
            inputTextField.resignFirstResponder()
        } else {
//            inputTextField.endEditing(true)
            inputTextField.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(BardEditorViewController.keyboardWillAppear(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(BardEditorViewController.keyboardWillDisappear(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(BardEditorViewController.textFieldTextChanged(_:)),
            name: UITextFieldTextDidChangeNotification,
            object: inputTextField
        )
        
    }
    
    func textFieldTextChanged(sender : AnyObject) {
        // iterate through every words, see if it exists in wordTagMap
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(displayInvalidWords), object: nil)
        performSelector(#selector(displayInvalidWords), withObject: nil, afterDelay: 1)
    }
    
    func displayInvalidWords() {
        let missingWordList = getInvalidWords()
        
        if !missingWordList.isEmpty {
            let missingWords = missingWordList.joinWithSeparator(",")
            if let drop = UIApplication.sharedApplication().keyWindow?.subviews.last as? Drop {
                (drop.subviews.last as! UILabel).text = "Unavailable words: \(missingWords)"
            } else {
                Drop.down("Unavailable words: \(missingWords)", state: .Error, duration: 60)
            }
        } else {
            Drop.upAll()
        }
        
    }
    
    func getInvalidWords() -> [String] {
        var missingWordList = [String]()
        
        for word in (inputTextField.text?.componentsSeparatedByString(" "))! {
            if !word.isEmpty && wordTagMap[word] == nil {
                missingWordList.append(word)
            }
        }
        
        return missingWordList
    }
    
    func keyboardWillAppear(notification: NSNotification){
        controlButton.setImage(UIImage(named: "icon_plus"), forState: UIControlState.Normal)
        isKeyboardShown = true
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        controlButton.setImage(UIImage(named: "icon_keyboard"), forState: UIControlState.Normal)
        isKeyboardShown = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    
    func initCollectionView() {
        // http://stackoverflow.com/a/16570399/803865
        wordTagCollectionView.contentInset=UIEdgeInsetsMake(20.0,20.0,20.0,20.0)
        wordTagCollectionView.delegate = self
        wordTagCollectionView.dataSource = self
        wordTagCollectionView.registerClass(WordTagCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
    }
    
    @IBAction func shareRepository(sender: UIBarButtonItem) {
        let repository = Repository.find(repositoryId!)

        let objectsToShare = [repository.getFileUrl()]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
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
    
    
    // http://stackoverflow.com/a/22675450/803865
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let wordTagString = self.wordTagStringList[indexPath.row]
        let word = wordTagString.componentsSeparatedByString(":")[0]
        
        if let selectedTextRange = inputTextField.selectedTextRange {
            inputTextField.replaceRange(selectedTextRange, withText: " \(word) ")
        } else {
            inputTextField.text = "\(inputTextField.text!) \(word)"
        }
        
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
        
        Analytics.timeEvent("generateBardVideo")
        
        if self.activityIndicator == nil {
            self.activityIndicator = addActivityIndicator(self.player.view)
        }
        
        // http://stackoverflow.com/questions/10781291/center-uiactivityindicatorview-in-a-uiimageview
        // http://stackoverflow.com/questions/17530659/uiactivityindicatorview-animation-delayed
        self.activityIndicator?.startAnimating()
        
        let wordTagStrings = getWordTagStrings(text)
        let segmentUrls = wordTagStrings.map { wordTagString in
            segmentUrlFromWordTag(wordTagString)
            }.flatMap { $0 }
        
        fetchSegments(segmentUrls, completion: { filePaths in
            VideoMerger.mergeMultipleVideos(filePaths, finished: { outputURL, localIdentifier in
                Repository.create(wordTagStrings, username: UserConfig.getUsername(), fileName: outputURL.pathComponents!.last!, localIdentifier: localIdentifier, characterToken: self.character.token, sceneToken: self.scene?.token, repoCreated: { repoId in
                    
                    self.activityIndicator?.stopAnimating()
                    self.repositoryId = repoId
                    Analytics.track("generateBardVideo",
                                    properties: ["wordTags" : wordTagStrings,
                                                 "characterToken" : self.character.token,
                                                 "sceneToken" : self.scene?.token ?? "",
                                                 "character" : self.character.name,
                                                 "scene": self.scene?.name ?? ""])
                    self.playVideo(outputURL)
                    self.shareButton.enabled = true
                })
                
            })
        })

    }
    
    // http://stackoverflow.com/a/11909880/803865
    
    func fetchSegments(segmentUrls: [String], completion: ([String] -> Void)? = nil ) {
        let group = dispatch_group_create()
        
        for segmentUrl in segmentUrls {
            dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                Storage.saveRemoteVideo(segmentUrl)
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(),{
            var filePaths = [String]()
            
            for segmentUrl in segmentUrls {
                let filePath = Storage.getSegmentFilePathFromUrl(segmentUrl)
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
        if let token = scene?.token  {
            return try! Realm().objects(Scene.self).filter("token = '\(token)'")
        } else {
            return try! Realm().objects(Scene.self).filter("characterToken = '\(character.token)'")
        }
    }
    
    func initDictionary() {
        for scene in getScenes() {
            if let wordList = scene.wordList {
                addWordListToDictionary(wordList)
            } else {
                BardClient.getSceneWordList(character.token, sceneToken: self.scene?.token, success: { value in
                    if let sceneWordList = value["wordList"] as? String {
                        let realm = try! Realm()
                        try! realm.write {
                            scene.wordList = sceneWordList
                        }
                        
                        self.addWordListToDictionary(sceneWordList)
                        self.wordTagCollectionView.reloadData()
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
    
    // https://coderwall.com/p/6onn0g/adding-progress-icon-programmatically-to-a-new-uiview
    
    func addActivityIndicator(view: UIView) -> UIActivityIndicatorView {
        let progressIcon = UIActivityIndicatorView()
        progressIcon.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        // http://stackoverflow.com/a/10781464
        progressIcon.center = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
        view.addSubview(progressIcon)
        return progressIcon
    }
    
    func playVideo(fileUrl: NSURL) {
        self.player.setUrl(fileUrl)
        self.player.playFromBeginning()
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
