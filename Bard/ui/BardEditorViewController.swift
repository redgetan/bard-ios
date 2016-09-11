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
import EZLoadingActivity


class BardEditorViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate {
    let cdnPath = "https://d22z4oll34c07f.cloudfront.net"
    var character: Character!
    var scene: Scene? = nil
    var isBackspacePressed: Bool = false
    var lastTokenCount: Int = 0
    var skipAddToWordTag: Bool = false
    var previousSelectedTokenIndex = [Int]()
    // word -> array of wordtagstrings 
    // useful for knowing whether a word is in the bard dictionary (valid or not)
    // (i.e wordTagMap["hello"] == ["hello:11342","hello:kj8s3n"])
    var wordTagMap: [String: [String]] = [String: [String]]()
    
    // list of wordtag strings to be used for collectionview, rendering word tags that user can click on
    var wordTagStringList: [String] = [String]()
    
    // the actual array of word tags that have been inputed by the user
    // it can contain either word (hello) or a wordtag (hello:45k8sn)
    // on generateBardVideo, all words would be searched for matching wordtag
    var wordTagList: [String] = [String]()
    
    var player: Player!
    var isKeyboardShown: Bool = false
    var activityIndicator: UIActivityIndicatorView? = nil
    var repositoryId: Int? = nil

    @IBOutlet weak var playerContainer: UIView!
    
    @IBOutlet weak var playerAspectRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var inputTextField: UITextView!
    @IBOutlet weak var controlButton: UIButton!
    @IBOutlet weak var wordTagCollectionView: UICollectionView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    let cellIdentifier = "wordTagCollectionViewCell"
    let sizingCell: WordTagCollectionViewCell = WordTagCollectionViewCell()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        inputTextField.delegate = self
        updateTitle()
        initPlayer()
        initDictionary()
        initCollectionView()
    }
    
    
    @IBAction func onControlButtonClick(sender: UIButton) {
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
            name: UITextViewTextDidChangeNotification,
            object: inputTextField
        )
        
    }
    
    func updateTitle() {
      self.title = scene?.name ?? character.name
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == ""){
            isBackspacePressed = true
        }
        return true
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        let wordRanges = textView.text.wordRanges()
        var index = 0
        
        for range in wordRanges {
            if NSIntersectionRange(textView.selectedRange,range).length != 0 {
                previousSelectedTokenIndex.append(index)
            }
            index = index + 1
        }
    }
    
    
    func textFieldTextChanged(sender : AnyObject) {
        // add word to wordTagList
        addWordToWordTagList()

        // validate words
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(displayInvalidWords), object: nil)
        performSelector(#selector(displayInvalidWords), withObject: nil, afterDelay: 1)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "editorToScene") {
            let nav = segue.destinationViewController as! UINavigationController
            let viewController = nav.topViewController as! SceneSelectViewController
            viewController.character = self.character
        }
    }
    
    func addWordToWordTagList() {
        if skipAddToWordTag {
            return
        }
        
        let tokenCount = getInputTokenCount()
        let tokenIndex = getInputTokenIndex()
        let addedCharacter = getAddedCharacter()
        
        while tokenCount < lastTokenCount {
            wordTagList.removeAtIndex(tokenIndex)
            lastTokenCount = lastTokenCount - 1
        }
        
        if isBackspacePressed == true {
            isBackspacePressed = false

            
            if tokenIndex < wordTagList.count {
                let wordAtInputField = getWordAtTokenIndex(tokenIndex)
                let wordAtWordTagList = wordTagList[tokenIndex].componentsSeparatedByString(":")[0]
                if !wordAtInputField.isEmpty && wordAtWordTagList != wordAtInputField {
                    wordTagList[tokenIndex] = wordAtInputField
                }
            }
            
        } else if addedCharacter == " " {
            if tokenCount != lastTokenCount {
                let wordAtInputField = getWordAtTokenIndex(tokenIndex)
                let prevWordAtInputField = getWordAtTokenIndex(tokenIndex - 1)

                if !wordAtInputField.isEmpty {
                    wordTagList.insert(wordAtInputField, atIndex: tokenIndex)
                    wordTagList[tokenIndex - 1] = prevWordAtInputField
                }
            }
        } else if !addedCharacter.isEmpty {
            let wordAtInputField = getWordAtTokenIndex(tokenIndex)

            if tokenCount != lastTokenCount {
                wordTagList.insert(wordAtInputField, atIndex: tokenIndex)
            } else {
                wordTagList[tokenIndex] = wordAtInputField
            }
        }
        
        lastTokenCount = tokenCount
    }
    
    func getWordAtTokenIndex(tokenIndex: Int) -> String {
        let words = inputTextField.text.characters.split{$0 == " "}.map(String.init)
        if tokenIndex < words.count {
            return words[tokenIndex].lowercaseString
        } else {
            return ""
        }
    }
    
    func getAddedCharacter() -> String {
        let cursorPosition = getCursorPosition()
        
        if cursorPosition == 0 {
            return ""
        }
        
        let indexUntilCursor  = inputTextField.text.startIndex.advancedBy(cursorPosition    )
        let indexBeforeCursor = inputTextField.text.startIndex.advancedBy(cursorPosition - 1)
        let range = indexBeforeCursor..<indexUntilCursor
        
        return inputTextField.text.substringWithRange(range)
    }
    
    func getInputTokenIndex() -> Int {
        let indexStartOfText = inputTextField.text.startIndex.advancedBy(getCursorPosition())
        let textUntilCursor  = inputTextField.text.substringToIndex(indexStartOfText)
        let spaceSeparators = Helper.matchesForRegexInText("\\s+", text: textUntilCursor)
        
        let spaceRanges = Helper.matchesForRegexInRange("\\s+", text: textUntilCursor)
        
        let isSpacePresentInTextBeginning = !spaceRanges.isEmpty && spaceRanges.first?.location == 0
        if isSpacePresentInTextBeginning {
            return spaceSeparators.count - 1
        } else {
            return spaceSeparators.count
        }

        
    }
    
    func getInputTokenCount() -> Int {
        return inputTextField.text.characters.split{$0 == " "}.count
    }
    
    func getCursorPosition() -> Int {
        let selectedRange = inputTextField.selectedTextRange!
            
        let cursorPosition = inputTextField.offsetFromPosition(inputTextField.beginningOfDocument, toPosition: selectedRange.start)
        
        return cursorPosition
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
        
        let info : NSDictionary = notification.userInfo!
        let keyboardHeight = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size.height
        let windowHeight = UIScreen.mainScreen().applicationFrame.size.height
        let newVideoPlayerHeight = windowHeight - keyboardHeight!
                                                - controlsContainer.frame.size.height
                                                - self.navigationController!.navigationBar.frame.height
        
        if keyboardHeight > wordTagCollectionView.frame.size.height {
            playerAspectRatioConstraint.setMultiplier(self.playerContainer.frame.size.width / newVideoPlayerHeight)
            self.view.layoutIfNeeded()
        }
        
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
        wordTagCollectionView.contentInset=UIEdgeInsetsMake(20.0,20.0,20.0,50.0)
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
        
        // insert wordtagstring into tokeindex
        wordTagList.insert(wordTagString, atIndex: getInputTokenIndex())
        
        // insert word in uitextview
        skipAddToWordTag = true
        if let selectedTextRange = inputTextField.selectedTextRange {
            inputTextField.replaceRange(selectedTextRange, withText: " \(word) ")
        } else {
            inputTextField.text = "\(inputTextField.text!) \(word)"
        }
        lastTokenCount = getInputTokenCount()
        skipAddToWordTag = false
        
        // scroll cursor in uitextview to bottom
        let bottom = NSMakeRange(inputTextField.text.characters.count - 1, 1)
        inputTextField.scrollRangeToVisible(bottom)
    }
    
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let wordTagString = self.wordTagStringList[indexPath.row]
        let word = wordTagString.componentsSeparatedByString(":")[0]
        self.sizingCell.textLabel.text = word;
        return self.sizingCell.intrinsicContentSize()
    }

    @IBAction func onPlayButtonClick(sender: UIButton) {
        generateBardVideo()
    }
    
    func generateBardVideo() {
        Analytics.timeEvent("generateBardVideo")
        
        if self.activityIndicator == nil {
            self.activityIndicator = addActivityIndicator(self.player.view)
        }
        
        // http://stackoverflow.com/questions/10781291/center-uiactivityindicatorview-in-a-uiimageview
        // http://stackoverflow.com/questions/17530659/uiactivityindicatorview-animation-delayed
        self.activityIndicator?.startAnimating()
        
        let wordTagStrings = getWordTagStrings()
        let segmentUrls = wordTagStrings.map { wordTagString in
            segmentUrlFromWordTag(wordTagString)
            }.flatMap { $0 }
        
        let phrase = wordTagStrings.map { wordTagString in wordTagString.componentsSeparatedByString(":")[0]}.joinWithSeparator(" ")
        
        if phrase.isEmpty {
            print("text is blank. type something")
            return
        }
        
        let destinationPath = Storage.getMergeVideoFilePath(character.name, text: phrase)
        
        fetchSegments(segmentUrls, completion: { filePaths in
            VideoMergeManager.mergeMultipleVideos(destinationPath: destinationPath,
                filePaths: filePaths,
                finished: { (error: NSError?, outputURL: NSURL?) in
                    if error != nil {
                        print(error)
                    }
                    else if outputURL == nil {
                        print("failed to merge videos")
                    }
                    else {
                        Repository.create(wordTagStrings,
                            username: UserConfig.getUsername(),
                            fileName: outputURL!.pathComponents!.last!,
                            localIdentifier: nil,
                            characterToken: self.character.token,
                            sceneToken: self.scene?.token, repoCreated: { repoId in
                                
                                self.activityIndicator?.stopAnimating()
                                self.repositoryId = repoId
                                Analytics.track("generateBardVideo",
                                    properties: ["wordTags" : wordTagStrings,
                                        "characterToken" : self.character.token,
                                        "sceneToken" : self.scene?.token ?? "",
                                        "character" : self.character.name,
                                        "scene": self.scene?.name ?? ""])
                                self.playVideo(outputURL!)
                                self.shareButton.enabled = true
                        })
                    
                    }
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

    
    func getWordTagStrings() -> [String] {
        var wordTagStrings = [String]()
        var word: String
        
        for wordTagString in wordTagList {
            if wordTagString.characters.contains(":") {
                wordTagStrings.append(wordTagString)
            } else {
                word = wordTagString
                guard let wordTagString = randomWordTagFromWord(word) else {
                    print("missing word \(word)")
                    continue
                }
                
                wordTagStrings.append(wordTagString)
            }
            
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


    
    func initDictionary() {
        if let selectedScene = self.scene {
            initSceneWordList(selectedScene)
        } else {
            initCharacterWordList()
        }
        
    }
    
    func initSceneWordList(selectedScene: Scene) {
        if selectedScene.wordList.isEmpty {
            BardClient.getSceneWordList(character.token, sceneToken: selectedScene.token, success: { value in
                if let sceneWordList = value["wordList"] as? String {
                    let realm = try! Realm()
                    try! realm.write {
                        selectedScene.wordList = sceneWordList
                    }
                    
                    self.addWordListToDictionary(sceneWordList)
                    self.wordTagCollectionView.reloadData()
                }
                
                }, failure: { errorMessage in
                    Drop.down("Failed to load word list", state: .Error, duration: 3)
            })
        } else {
            addWordListToDictionary(selectedScene.wordList)
            self.wordTagCollectionView.reloadData()
        }
    }
    
    func initCharacterWordList() {
        if self.character.isBundleDownloaded {
            let scenes = Scene.forCharacterToken(self.character.token)
            
            for scene in scenes {
                addWordListToDictionary(scene.wordList)
            }
            
            self.wordTagCollectionView.reloadData()
        } else {
            EZLoadingActivity.show("Downloading Word List...", disableUI: true)
            BardClient.getCharacterWordList(self.character.token, success: { value in
                for (sceneToken, wordList) in value as! NSDictionary {
                    if Scene.forToken(sceneToken as! String) == nil {
                        Scene.createWithTokenAndWordList(sceneToken as! String, characterToken: self.character.token, wordList: wordList as! String)
                        self.addWordListToDictionary(wordList as! String)
                    }
                }
                
                let realm = try! Realm()
                try! realm.write {
                    self.character.isBundleDownloaded = true
                }
                
                EZLoadingActivity.hide()
                self.wordTagCollectionView.reloadData()
                
                }, failure: { errorMessage in
                    EZLoadingActivity.hide(success: false, animated: true)
            })
        }
    }
    
    
    @IBAction func unwindToEditor(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.sourceViewController as? SceneSelectViewController {
            
            // reset dictionary
            self.wordTagStringList.removeAll()

            // set scene
            self.scene = sourceViewController.selectedScene
            
            updateTitle()
            initDictionary()
        }
    }
    
    func addWordListToDictionary(wordList: String) {
        var word: String

        for wordTagString in wordList.componentsSeparatedByString(",") {
            if wordTagString.isEmpty {
                continue
            }
            
            wordTagStringList.append(wordTagString)
            
            word = wordTagString.componentsSeparatedByString(":")[0]
        
            if wordTagMap[word] != nil {
                if !wordTagMap[word]!.contains(wordTagString) {
                    wordTagMap[word]!.append(wordTagString)
                }
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
    
    func initControls() {
        if self.scene != nil {
            inputTextField.hidden = true
            controlButton.hidden  = true
        }
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
