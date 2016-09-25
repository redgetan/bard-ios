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
    var skipTextSelectionChange: Bool = false
    var previousSelectedTokenIndex = [Int]()
    var wordTagSelector: WordTagSelector!
    var wordTagPaginationLabel: UILabel!
    var outputURL: NSURL!
    
    // word -> array of wordtagstrings 
    // useful for knowing whether a word is in the bard dictionary (valid or not)
    // (i.e wordTagMap["hello"] == ["hello:11342","hello:kj8s3n"])
    
    // this is used in fetching wordtags for charactereditor (all scenes)
    // it is also used for checking whether word is valid (in dictionary), regardless of whether its charactereditor or sceneeditor
    var wordTagMap: [String: [String]] = [String: [String]]()
    
    // list of wordtag strings to be used for collectionview, rendering word tags that user can click on
    var wordTagStringList: [String] = [String]()
    
    // the actual array of word tags that have been inputed by the user
    // it can contain either word (hello) or a wordtag (hello:45k8sn)
    // on generateBardVideo, all words would be searched for matching wordtag
    var wordTagList: [String] = [String]()

    
    var outputWordTagStrings: [String] = [String]()
    var outputPhrase: String = ""

    
    // the active index of wordTagList
    var currentWordTagListIndex: Int = 0
    
    var findPrevButton: UIButton!
    var findNextButton: UIButton!

    var player: Player!
    var isKeyboardShown: Bool = false
    var activityIndicator: UIActivityIndicatorView? = nil
    var previousSelectedPreviewThumbnail: PreviewTimelineCollectionViewCell? = nil
    
    @IBOutlet weak var sceneSelectButton: UIButton!
    @IBOutlet weak var generateButton: UIButton!
    @IBOutlet weak var previewTimelineCollectionView: UICollectionView!
    @IBOutlet weak var playerContainer: UIView!
    
    @IBOutlet weak var playerAspectRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var inputTextField: UITextView!
    @IBOutlet weak var controlButton: UIButton!
    @IBOutlet weak var wordTagCollectionView: UICollectionView!
    
    let cellIdentifier = "wordTagCollectionViewCell"
    let previewTimelineCellIdentifier = "previewTimelineCollectionViewCell"

    let sizingCell: WordTagCollectionViewCell = WordTagCollectionViewCell()
    var originatingViewController: UIViewController? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.automaticallyAdjustsScrollViewInsets = false
        
        inputTextField.delegate = self
        updateTitle()
        initPlayer()
        initDictionary()
        initPreviewTimeline()
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
    
    override func viewDidAppear(animated: Bool) {
        if (originatingViewController as? SceneSelectViewController) != nil {
            originatingViewController = nil
            
            if let selectedScene = self.scene {
                sceneSelectButton.hnk_setImageFromURL(NSURL(string: selectedScene.thumbnailUrl)!)
            } else {
                sceneSelectButton.setImage(UIImage(named: "icon_bookmark"), forState: UIControlState.Normal)
            }

        }
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
        
        // if selection is result of clicking on wordTag, dont need to set word tag again
        if skipTextSelectionChange == false {
            self.currentWordTagListIndex = getInputTokenIndex()
            if self.wordTagList.count > self.currentWordTagListIndex {
                let wordTagString = self.wordTagList[self.currentWordTagListIndex]
                if self.wordTagSelector.setWordTag(wordTagString) {
                    onWordTagChanged(wordTagString)
                }
            }
  
        }
        
        
        
        
//        let wordRanges = textView.text.wordRanges()
//        var index = 0
//        
//        for range in wordRanges {
//            if NSIntersectionRange(textView.selectedRange,range).length != 0 {
//                previousSelectedTokenIndex.append(index)
//            }
//            index = index + 1
//        }
    }
    
    
    func textFieldTextChanged(sender : AnyObject) {
        // add word to wordTagList
        addWordToWordTagList()

        // validate words
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(displayInvalidWords), object: nil)
        performSelector(#selector(displayInvalidWords), withObject: nil, afterDelay: 1)
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if (identifier == "editorToShare") {
            return false
        } else {
            return true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "editorToScene") {
            let nav = segue.destinationViewController as! UINavigationController
            let viewController = nav.topViewController as! SceneSelectViewController
            viewController.character = self.character
        } else if (segue.identifier == "editorToShare") {
            let viewController = segue.destinationViewController as! ShareEditorViewController
            viewController.character = self.character
            viewController.outputURL = self.outputURL
            viewController.outputPhrase = self.outputPhrase
            viewController.outputWordTagStrings = self.outputWordTagStrings
        }
    }
    
    func addWordToWordTagList() {
        
        if skipAddToWordTag {
            return
        }
        
        let tokenCount = getInputTokenCount()
        let tokenIndex = getInputTokenIndex()
        let addedCharacter = getAddedCharacter()
        let isLeaderPressed = addedCharacter == " "
        
        print("ontextchange: \(currentWordTagListIndex), addedCharacter: \(addedCharacter),isBackspacePressed: \(isBackspacePressed), wordTagList: \(wordTagList)")

        
        while tokenCount < lastTokenCount {
            // at this point, 3rd word is already deleted, 
            // tokenIndex points to 2nd word, so in order to delete 3rd word from the in-memory wordTagList,
            // use tokenIndex + 1
            
            // only exception is if we're deleting last item in wordTagList (index 0, size 1)
            if tokenIndex + 1 == wordTagList.count {
                wordTagList.removeAtIndex(tokenIndex)
            } else if tokenIndex + 1 < wordTagList.count {
                wordTagList.removeAtIndex(tokenIndex + 1)
            }
            lastTokenCount = lastTokenCount - 1
            previewTimelineCollectionView.reloadData()
            previewTimelineCollectionView.layoutIfNeeded()
        }
        
        // possibly due to race condition or just bug in my code, sometimes isBackspacePressed would be true even if
        // addedCharacter contains character. Add another condition to check for presence of character
        if isBackspacePressed == true && addedCharacter.isEmpty {
            // deleting wordTag from list
            isBackspacePressed = false

            
            if tokenIndex < wordTagList.count {
                let wordAtInputField = getWordAtTokenIndex(tokenIndex)
                let wordAtWordTagList = wordTagList[tokenIndex].componentsSeparatedByString(":")[0]
                if !wordAtInputField.isEmpty && wordAtWordTagList != wordAtInputField {
                    wordTagList[tokenIndex] = wordAtInputField
                    
                    if wordAtInputField.characters.contains(":") {
                        previewTimelineCollectionView.reloadData()
                        previewTimelineCollectionView.layoutIfNeeded()
                    }
                   
                }
            }
            
        } else if isLeaderPressed {
            // 1 word split into 2 words (assign wordTag to both)
            if tokenCount != lastTokenCount {
                let wordAtInputField = getWordAtTokenIndex(tokenIndex)
                let prevWordAtInputField = getWordAtTokenIndex(tokenIndex - 1)

                if !wordAtInputField.isEmpty {
                    // assign tag for latter half of split-word
                    if let wordTagString = self.wordTagSelector.findRandomWordTag(wordAtInputField) {
                        wordTagList.insert(wordTagString, atIndex: tokenIndex)
                    } else {
                        wordTagList.insert(wordAtInputField, atIndex: tokenIndex)
                    }
                    
                    // assign tag for former half of split-word
                    if let wordTagString = self.wordTagSelector.findRandomWordTag(wordAtInputField) {
                        wordTagList[tokenIndex - 1] = wordTagString
                        onWordTagChanged(wordTagString)
                    } else {
                        wordTagList[tokenIndex - 1] = prevWordAtInputField
                    }
                }
            } else {
                // assign wordTag to last
                let wordAtInputField = getWordAtTokenIndex(tokenIndex)
                if !wordAtInputField.isEmpty {
                    if let wordTagString = self.wordTagSelector.findRandomWordTag(wordAtInputField) {
                        wordTagList[tokenIndex] = wordTagString
                        onWordTagChanged(wordTagString)
                    } else {
                        wordTagList[tokenIndex] = wordAtInputField
                    }
                }
            }
        } else if !addedCharacter.isEmpty {
            // adding untagged word/character
            let wordAtInputField = getWordAtTokenIndex(tokenIndex)

            if tokenCount != lastTokenCount || wordTagList.isEmpty {
                wordTagList.insert(wordAtInputField, atIndex: tokenIndex)
            } else {
                wordTagList[tokenIndex] = wordAtInputField
            }
        }
        
        print("ontextchange [post] wordTagList: \(wordTagList)")
        drawGenerateButton()

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
        let trimmedText      = textUntilCursor.stringByTrimmingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet()
        )
        let spaceSeparators = Helper.matchesForRegexInText("\\s+", text: trimmedText)
        
        let spaceRanges = Helper.matchesForRegexInRange("\\s+", text: trimmedText)
        
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
            if !word.isEmpty && wordTagMap[word.lowercaseString] == nil {
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
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextViewTextDidChangeNotification, object: inputTextField)
    }

    func initPreviewTimeline() {
        previewTimelineCollectionView.contentInset = UIEdgeInsetsMake(0.0,0.0,0.0,0.0)
        previewTimelineCollectionView.delegate = self
        previewTimelineCollectionView.dataSource = self
        
        generateButton.hidden = true
    }
    
    func initCollectionView() {
        // http://stackoverflow.com/a/16570399/803865
        wordTagCollectionView.contentInset=UIEdgeInsetsMake(20.0,20.0,20.0,50.0)
        wordTagCollectionView.delegate = self
        wordTagCollectionView.dataSource = self
        wordTagCollectionView.registerClass(WordTagCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
    }
    
    
    @IBAction func cancel(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: UICollectionViewDataSource protocol
    
    func collectionView(collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.previewTimelineCollectionView {
            return self.wordTagList.count
        } else {
            return self.wordTagStringList.count
        }
        
    }
    
    // MARK: UICollectionViewDelegate protocol
    
    func collectionView(collectionView: UICollectionView,
                                 cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if collectionView == previewTimelineCollectionView {
            return initPreviewTimelineCollectionViewCell(collectionView, indexPath: indexPath)
        } else {
            return initWordTagCollectionViewCell(collectionView, indexPath: indexPath)
        }
        
    }
    
    // previewTimeline will look at previewThumbnails (an array of thumbnailUrls)
    // previewThumbnails
    
    func initPreviewTimelineCollectionViewCell(collectionView: UICollectionView, indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(previewTimelineCellIdentifier,
                                                                         forIndexPath: indexPath) as!PreviewTimelineCollectionViewCell
        
        let wordTagString = self.wordTagList[indexPath.row]
        // determine
//        cell.imageView.image = UIImage()
        
        if wordTagString.containsString(":") && cell.wordTagString != wordTagString {
            if let thumbnail = getThumbnailUrlFromWordTag(wordTagString) {
                cell.imageView.image = thumbnail
                cell.wordTagString = wordTagString
            }
            
//                cell.imageView.image = UIImage(named: "preview_image_test")
//                cell.imageView.image = UIImage(color: .redColor())
//                 cell.imageView.hnk_setImageFromURL(NSURL(string: url)!)
        }
        
        return cell
    }
    
    func getThumbnailUrlFromWordTag(wordTagString: String) -> UIImage? {
        guard let segmentUrl = segmentUrlFromWordTag(wordTagString) else {
            return nil
        }
        
        do {
            let filePath = Storage.getSegmentFilePathFromUrl(segmentUrl)
        
            let asset = AVURLAsset(URL: NSURL(fileURLWithPath: filePath))
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            let time = CMTimeMake(1, 1)
            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            return UIImage(CGImage: imageRef)
        } catch {
            return UIImage()
        }
        
//        return "https://d22z4oll34c07f.cloudfront.net/segments/F6nNlIbgWTU/thumbnail/8435.png"
//        return "\(cdnPath)/segments/\(scene.token)/thumbnails/\(tag).png"
    }
    
    func initWordTagCollectionViewCell(collectionView: UICollectionView, indexPath: NSIndexPath) -> UICollectionViewCell {
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
        if collectionView == previewTimelineCollectionView {
            didSelectPreviewTimeline(collectionView, didSelectItemAtIndexPath: indexPath)
        } else {
            didSelectWordTag(collectionView, didSelectItemAtIndexPath: indexPath)
        }
    }
    
    func didSelectPreviewTimeline(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.currentWordTagListIndex = indexPath.row
        let wordTagString = self.wordTagList[indexPath.row]
        
        if self.wordTagSelector.setWordTag(wordTagString) {
            onWordTagChanged(wordTagString)
        } else if wordTagString.characters.contains(":") {
            self.player.playFromBeginning()
            // highlight thumbnail even if same wordtagstring (to account for change in indexPath.row)
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PreviewTimelineCollectionViewCell
            highlightImageView(cell)
        }
        
        
        // highlight word
        highlightWordAtTokenIndex(indexPath.row)
    }
    
    func highlightWordAtTokenIndex(tokenIndex: Int) {
        let (startPosition, endPosition) = getWordPositionFromTokenIndex(tokenIndex)
        if startPosition != nil && endPosition != nil {
            inputTextField.becomeFirstResponder()
            skipTextSelectionChange = true
            inputTextField.selectedTextRange = inputTextField.textRangeFromPosition(startPosition!, toPosition: endPosition!)
            skipTextSelectionChange = false
        }
    }
    
    func getWordPositionFromTokenIndex(tokenIndex: Int) -> (UITextPosition?, UITextPosition?) {
        let wordPositions = inputTextField.text.wordPositions()
        let (start, end) = wordPositions[tokenIndex]

        if wordPositions.count > tokenIndex {
            let startPosition = inputTextField.positionFromPosition(inputTextField.beginningOfDocument, inDirection: UITextLayoutDirection.Right, offset: start)
            let endPosition = inputTextField.positionFromPosition(inputTextField.beginningOfDocument, inDirection: UITextLayoutDirection.Right, offset: end)
            return (startPosition, endPosition)
        } else {
            return (nil, nil)
        }
        
    }
    
    func highlightImageView(cell: PreviewTimelineCollectionViewCell) {
        // unhighlight previous
        unHighlightPreviousImageView()
        
        // highlight current
        cell.imageView.layer.borderWidth = 2
        cell.imageView.layer.borderColor = UIColor(hex: "#03A9F4").CGColor
        
        previousSelectedPreviewThumbnail = cell
    }
    
 
    func unHighlightPreviousImageView() {
        for visible in previewTimelineCollectionView.visibleCells() as! [PreviewTimelineCollectionViewCell] {
            visible.imageView.layer.borderColor = UIColor.blackColor().CGColor
        }
    }
    
    func didSelectWordTag(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let wordTagString = self.wordTagStringList[indexPath.row]
        let word = wordTagString.componentsSeparatedByString(":")[0]
        let tokenCountBeforeWordTagClick = getInputTokenCount()
        
        // insert word in uitextview
        skipAddToWordTag = true
        skipTextSelectionChange = true
        if let selectedTextRange = inputTextField.selectedTextRange {
            inputTextField.replaceRange(selectedTextRange, withText: " \(word) ")
        } else {
            inputTextField.text = "\(inputTextField.text!) \(word)"
        }
        lastTokenCount = getInputTokenCount()
        skipAddToWordTag = false
        skipTextSelectionChange = false
        
        // scroll cursor in uitextview to bottom
        let bottom = NSMakeRange(inputTextField.text.characters.count - 1, 1)
        inputTextField.scrollRangeToVisible(bottom)
    
        self.currentWordTagListIndex = getInputTokenIndex()
        
        if self.wordTagSelector.setWordTag(wordTagString, force: true) {
            if lastTokenCount > tokenCountBeforeWordTagClick {
                wordTagList.insert(wordTagString, atIndex: self.currentWordTagListIndex)
            } else {
                wordTagList[self.currentWordTagListIndex] = wordTagString
            }
            print("wordTagClick - wordTagList is \(wordTagList)")
            onWordTagChanged(wordTagString)
        }
        
        drawGenerateButton()
    }
    
    func drawGenerateButton() {
        if getTagCountInWordTagList() > 1 {
            generateButton.hidden = false
        } else {
            generateButton.hidden = true
        }
    }
    
    func getTagCountInWordTagList() -> Int {
        var i = 0
        
        for wordTagString in wordTagList {
            if wordTagString.characters.contains(":") {
                i += 1
            }
        }
        
        return i
    }
    
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if collectionView == previewTimelineCollectionView {
            return CGSizeMake(50, 50)
        } else {
            let wordTagString = self.wordTagStringList[indexPath.row]
            let word = wordTagString.componentsSeparatedByString(":")[0]
            self.sizingCell.textLabel.text = word;
            return self.sizingCell.intrinsicContentSize()
        }
    }

    
    @IBAction func onGenerateButtonClick(sender: UIButton) {
        self.generateButton.enabled = false
        self.generateButton.backgroundColor = UIColor.blackColor()
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
        
        self.outputWordTagStrings = getWordTagStrings()
        let segmentUrls = self.outputWordTagStrings.map { wordTagString in
            segmentUrlFromWordTag(wordTagString)
            }.flatMap { $0 }
        
        self.outputPhrase = self.outputWordTagStrings.map { wordTagString in wordTagString.componentsSeparatedByString(":")[0]}.joinWithSeparator(" ")
        
        if self.outputPhrase.isEmpty {
            print("text is blank. type something")
            return
        }
        
        let destinationPath = Storage.getMergeVideoFilePath()
        if NSFileManager.defaultManager().fileExistsAtPath(destinationPath) {
            Storage.removeFile(destinationPath)
        }
        
        fetchSegments(segmentUrls, completion: { filePaths in
            VideoMergeManager.mergeMultipleVideos(destinationPath: destinationPath,
                filePaths: filePaths,
                finished: { (error: NSError?, outputURL: NSURL?) in
                    self.activityIndicator?.stopAnimating()
                    self.generateButton.enabled = true
                    self.generateButton.backgroundColor = UIColor(hex: "#2a9f47")

                    if error != nil {
                        print(error)
                    }
                    else if outputURL == nil {
                        print("failed to merge videos")
                    }
                    else {
                        Analytics.track("generateBardVideo",
                                    properties: ["wordTags" : self.outputWordTagStrings,
                                        "characterToken" : self.character.token,
                                        "sceneToken" : self.scene?.token ?? "",
                                        "character" : self.character.name,
                                        "scene": self.scene?.name ?? ""])

                        self.outputURL = outputURL!
                        self.performSegueWithIdentifier("editorToShare", sender: nil)
                    
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
                    
                    self.addWordListToSceneDictionary(sceneWordList)
                    self.wordTagCollectionView.reloadData()
                }
                
                }, failure: { errorMessage in
                    Drop.down("Failed to load word list", state: .Error, duration: 3)
            })
        } else {
            addWordListToSceneDictionary(selectedScene.wordList)
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
            self.originatingViewController = sourceViewController
            
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
        
            if self.wordTagMap[word] != nil {
                if !self.wordTagMap[word]!.contains(wordTagString) {
                    self.wordTagMap[word]!.append(wordTagString)
                }
            } else {
                self.wordTagMap[word] = [String]()
                self.wordTagMap[word]!.append(wordTagString)
            }
            
            
        }
        
        self.wordTagSelector = WordTagSelector(wordTagMap: self.wordTagMap)
    }
    
    func addWordListToSceneDictionary(wordList: String) {
        var word: String
        var sceneWordTagMap: [String: [String]] = [String: [String]]()
        
        for wordTagString in wordList.componentsSeparatedByString(",") {
            if wordTagString.isEmpty {
                continue
            }
            
            wordTagStringList.append(wordTagString)
            
            word = wordTagString.componentsSeparatedByString(":")[0]
        
            if sceneWordTagMap[word] != nil {
                if !sceneWordTagMap[word]!.contains(wordTagString) {
                    sceneWordTagMap[word]!.append(wordTagString)
                }
            } else {
                sceneWordTagMap[word] = [String]()
                sceneWordTagMap[word]!.append(wordTagString)
            }
            
            
        }
        
        self.wordTagSelector.setSceneWordTagMap(sceneWordTagMap)
    }
    
    func onWordTagChanged(wordTagString: String, withDelay: NSTimeInterval? = nil) {
        guard let segmentUrl = segmentUrlFromWordTag(wordTagString) else {
            return
        }
        
        drawPagination(wordTagString)

        if let delay = withDelay {
            NSObject.cancelPreviousPerformRequestsWithTarget(self)
            performSelector(#selector(downloadSegmentPlayVideoAndHighlightThumbnail), withObject: segmentUrl, afterDelay: delay)
        } else {
            downloadSegmentPlayVideoAndHighlightThumbnail(segmentUrl)
        }
    }
    
    func downloadSegmentPlayVideoAndHighlightThumbnail(segmentUrl: String) {
        // download video if not cached to disk yet
        Storage.saveRemoteVideo(segmentUrl)
        let filePath = Storage.getSegmentFilePathFromUrl(segmentUrl)
        let segmentFileUrl = NSURL(fileURLWithPath: filePath)
        playVideo(segmentFileUrl)
        
        // let previewTimeline draw thumbnails once mp4 has been downloaded
        previewTimelineCollectionView.reloadData()
        previewTimelineCollectionView.layoutIfNeeded()
        
        // once thumbnails are drawn, we can highlight/select them
        let indexPath = NSIndexPath(forRow: currentWordTagListIndex, inSection: 0)
        
        var thumbnail = previewTimelineCollectionView.cellForItemAtIndexPath(indexPath) as? PreviewTimelineCollectionViewCell
        
        // if at first try thumbnail is nil, it means the cell item is currently not visible
        // try to scroll to that position to make it visibe, then re-attempt to fetch the thumbnail again
        if thumbnail == nil {
            // before we scroll some of previous cells outside of view, unhighlight them first
            unHighlightPreviousImageView()
            
            UIView.animateWithDuration(0.3, animations: {
                self.previewTimelineCollectionView.scrollToItemAtIndexPath(indexPath,
                    atScrollPosition: .CenteredHorizontally,
                    animated: false)
            }, completion: { (finished: Bool) -> Void in
                thumbnail = self.previewTimelineCollectionView.cellForItemAtIndexPath(indexPath) as? PreviewTimelineCollectionViewCell
                if thumbnail != nil {
                    self.highlightImageView(thumbnail!)
                }
            })
            
            
        } else {
            highlightImageView(thumbnail!)
        }

    }
    
    func drawPagination(wordTagString: String) {
        let word =  wordTagString.componentsSeparatedByString(":")[0]
        
        if let wordTagVariants = self.wordTagMap[word] {
            if let index = wordTagVariants.indexOf(wordTagString) {
                wordTagPaginationLabel.text = "\(index + 1) of \(wordTagVariants.count)"
            }
            
            self.findPrevButton.hidden = false
            self.findNextButton.hidden = false
            
            if wordTagVariants.count == 1 {
                self.findPrevButton.tintColor = UIColor.whiteColor()
                self.findNextButton.tintColor = UIColor.whiteColor()
            } else {
                self.findPrevButton.tintColor = UIColor(hex: "#03A9F4")
                self.findNextButton.tintColor = UIColor(hex: "#03A9F4")
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
        
        self.player.layerBackgroundColor = UIColor.blackColor()
        addWordTagPaginator()
    }
    
    func addWordTagPaginator() {
        // label
        wordTagPaginationLabel = UILabelWithPadding()
        wordTagPaginationLabel.textColor = UIColor.whiteColor()
        wordTagPaginationLabel.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        wordTagPaginationLabel.translatesAutoresizingMaskIntoConstraints = false
        wordTagPaginationLabel.font = UIFont.systemFontOfSize(16)

        
        self.player.view.addSubview(wordTagPaginationLabel)
        
        NSLayoutConstraint(item: wordTagPaginationLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: wordTagPaginationLabel, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.BottomMargin, multiplier: 1.0, constant: -10.0).active = true

        // back
        
        var button = UIButton()
        var image = UIImage(named: "icon_back_android")?.imageWithRenderingMode(.AlwaysTemplate)
        button.setImage(image, forState: .Normal)
        button.tintColor = UIColor.whiteColor()
        button.addTarget(self, action: #selector(onPrevBtnClick), forControlEvents: .TouchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.hidden = true
        
        self.findPrevButton = button
        self.player.view.addSubview(button)

        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.LeadingMargin, multiplier: 1.0, constant: -20.0).active = true
        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.TopMargin, multiplier: 1.0, constant: 0.0).active = true
        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.BottomMargin, multiplier: 1.0, constant: 0.0).active = true
        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 50).active = true
        
        // forward
        
        button = UIButton()
        image = UIImage(named: "icon_forward_android")?.imageWithRenderingMode(.AlwaysTemplate)
        button.setImage(image, forState: .Normal)
        button.tintColor = UIColor.whiteColor()
        button.addTarget(self, action: #selector(onNextBtnClick), forControlEvents: .TouchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.hidden = true
        
        self.findNextButton = button
        self.player.view.addSubview(button)
        
        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.TrailingMargin, multiplier: 1.0, constant: 20.0).active = true
        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.TopMargin, multiplier: 1.0, constant: 0.0).active = true
        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.BottomMargin, multiplier: 1.0, constant: 0.0).active = true
        NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 50).active = true
    }
    
    func onPrevBtnClick() {
        if self.wordTagSelector.getWordTagVariantCount() == 1 {
            self.player.playFromBeginning()
        } else if let wordTagString = self.wordTagSelector.findPrevWordTag() {
            self.wordTagList[self.currentWordTagListIndex] = wordTagString
            onWordTagChanged(wordTagString, withDelay: 0.5)
        }
    }
    
    func onNextBtnClick() {
        if self.wordTagSelector.getWordTagVariantCount() == 1 {
            self.player.playFromBeginning()
        } else if let wordTagString = self.wordTagSelector.findNextWordTag() {
            self.wordTagList[self.currentWordTagListIndex] = wordTagString
            onWordTagChanged(wordTagString, withDelay: 0.5)
        }
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
