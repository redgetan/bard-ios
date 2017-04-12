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
import Alamofire


class BardEditorViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate, PlayerDelegate {
    let cdnPath = Configuration.segmentsCdnPath
//    var character: Character!
//    var characterToken: String!
    var scene: Scene? = nil
    var isBackspacePressed: Bool = false
    var lastTokenCount: Int = 0
    var skipAddToWordTag: Bool = false
    var skipTextSelectionChange: Bool = false
    var previousSelectedTokenIndex = [Int]()
    var wordTagSelector: WordTagSelector?
    var wordTagPaginationLabel: UILabel!
    var wordUnavailableLabel: UILabel!
    var placeholderLabel : UILabel!

    
    var outputURL: NSURL!
    var characterDownloadRequest: Alamofire.Request?

    var assignWordTagTimer: NSTimer?
    
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
    
//    @IBOutlet weak var sceneSelectButton: UIButton!
    @IBOutlet weak var generateButton: UIButton!
    @IBOutlet weak var previewTimelineCollectionView: UICollectionView!
    @IBOutlet weak var playerContainer: UIView!
    
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var playerAspectRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var controlsContainer: UIView!
    @IBOutlet weak var inputTextField: UITextView!
    @IBOutlet weak var wordTagCollectionView: UICollectionView!
    
    @IBOutlet weak var keyboardToggleButton: UIButton!
    let cellIdentifier = "wordTagCollectionViewCell"
    let previewTimelineCellIdentifier = "previewTimelineCollectionViewCell"

    let sizingCell: WordTagCollectionViewCell = WordTagCollectionViewCell()
    var originatingViewController: UIViewController? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.automaticallyAdjustsScrollViewInsets = false
        
        initControls()
        updateTitle()
        initPlayer()

        initDictionary()
        initPreviewTimeline()
        initCollectionView()
    }
    
    func initControls() {
        inputTextField.delegate = self

        keyboardToggleButton.alpha = 0.5
        moreButton.tintColor = UIColor.whiteColor()
        
        placeholderLabel = UILabel()
        placeholderLabel.text = "say something"
        placeholderLabel.font = UIFont.systemFontOfSize(12)
        placeholderLabel.sizeToFit()
        inputTextField.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPointMake(5, inputTextField.font!.pointSize / 2)
        placeholderLabel.textColor = UIColor(white: 0, alpha: 0.3)
        placeholderLabel.hidden = !inputTextField.text.isEmpty
    }
    

    @IBAction func onMoreBtnClick(sender: UIButton) {
        showMoreOptions()
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(BardEditorViewController.keyboardWillAppear(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(BardEditorViewController.keyboardWillDisappear(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
//        NSNotificationCenter.defaultCenter().addObserver(
//            self,
//            selector: #selector(BardEditorViewController.textFieldTextChanged(_:)),
//            name: UITextViewTextDidChangeNotification,
//            object: inputTextField
//        )
        
    }
    
    override func viewDidAppear(animated: Bool) {
        if (originatingViewController as? SceneSelectViewController) != nil {
            originatingViewController = nil
            

        }
    }
    
    func attemptAssignWordTagDelayed(word: String, tokenIndex: Int) {
//        NSObject.cancelPreviousPerformRequestsWithTarget(self)
        let wordToTokenIndexMap: [String: Int] = [word : tokenIndex]
        
        self.assignWordTagTimer?.invalidate()
        self.assignWordTagTimer = NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: #selector(attemptAssignWordTag), userInfo: wordToTokenIndexMap, repeats: false)

//        performSelector(#selector(attemptAssignWordTag), withObject: , afterDelay: 1.5)
    }
    
    func attemptAssignWordTag(timer: NSTimer!) {
        let wordToTokenIndexMap: [String: Int] = timer.userInfo as! [String: Int]
        
        let word = ([String] (wordToTokenIndexMap.keys))[0]
        let tokenIndex = wordToTokenIndexMap[word]
        
        if let wordTagString = self.wordTagSelector?.findRandomWordTag(word) {
            wordTagList[tokenIndex!] = wordTagString
            onWordTagChanged(wordTagString)
        }
    }
    
    func updateTitle() {
      self.title = scene?.name
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == ""){
            isBackspacePressed = true
        } else {
            isBackspacePressed = false
        }
        return true
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        
        // if selection is result of clicking on wordTag, dont need to set word tag again
        if skipTextSelectionChange == false {
            self.currentWordTagListIndex = getInputTokenIndex()
            if self.wordTagList.count > self.currentWordTagListIndex {
                let wordTagString = self.wordTagList[self.currentWordTagListIndex]
                if (self.wordTagSelector?.setWordTag(wordTagString) != nil) {
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
    
    func textViewDidChange(textView: UITextView) {
//    func textFieldTextChanged(sender : AnyObject) {
        placeholderLabel.hidden = !inputTextField.text.isEmpty

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
            _ = nav.topViewController as! SceneSelectViewController
        } else if (segue.identifier == "editorToShare") {
            let viewController = segue.destinationViewController as! ShareEditorViewController
            viewController.scene = self.scene
            viewController.outputURL = self.outputURL
            viewController.outputPhrase = self.outputPhrase
            viewController.outputWordTagStrings = self.outputWordTagStrings
        }
    }
    
    func addWordToWordTagList() {
        self.assignWordTagTimer?.invalidate()
        
        if skipAddToWordTag {
            return
        }
        
        let tokenCount = getInputTokenCount()
        let tokenIndex = getInputTokenIndex()
        
        let characterBeforeCursor = getCharacterBeforeCursor()
        let isLeaderPressed = isBackspacePressed == false && characterBeforeCursor == " "
        let isUserDeleteKeyPressed = isBackspacePressed == true
        
        BardLogger.log("ontextchange: \(currentWordTagListIndex), characterBeforeCursor: \(characterBeforeCursor),isBackspacePressed: \(isBackspacePressed), wordTagList: \(wordTagList)")

        
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
        
        if isUserDeleteKeyPressed {
            // deleting wordTag from list
            
            if tokenIndex < wordTagList.count {
                let wordAtInputField = getWordAtTokenIndex(tokenIndex)
                let wordAtWordTagList = wordTagList[tokenIndex].componentsSeparatedByString(":")[0]
                if !wordAtInputField.isEmpty && wordAtWordTagList != wordAtInputField {
                    wordTagList[tokenIndex] = wordAtInputField
                    attemptAssignWordTagDelayed(wordAtInputField, tokenIndex: tokenIndex)
                    
                    if wordAtInputField.characters.contains(":") {
                        previewTimelineCollectionView.reloadData()
                        previewTimelineCollectionView.layoutIfNeeded()
                    }
                   
                }
            }
            
        } else if isLeaderPressed {
            // 1 word split into 2 words (assign wordTag to both)
            if tokenCount != lastTokenCount {
                let upperHalfWord = getWordAtTokenIndex(tokenIndex + 1)
                let lowerHalfWord = getWordAtTokenIndex(tokenIndex)

                if !upperHalfWord.isEmpty {
                    // assign tag for latter half of split-word
                    if let wordTagString = self.wordTagSelector?.findRandomWordTag(upperHalfWord) {
                        wordTagList.insert(wordTagString, atIndex: tokenIndex + 1)
                        onWordTagChanged(wordTagString)
                    } else {
                        wordTagList.insert(upperHalfWord, atIndex: tokenIndex + 1)
                    }
                    
                    // assign tag for former half of split-word
                    if let wordTagString = self.wordTagSelector?.findRandomWordTag(lowerHalfWord) {
                        wordTagList[tokenIndex] = wordTagString
                        onWordTagChanged(wordTagString)
                    } else {
                        wordTagList[tokenIndex] = lowerHalfWord
                    }
                }
            } else {
                // assign wordTag to last
                let wordAtInputField = getWordAtTokenIndex(tokenIndex)
                if !wordAtInputField.isEmpty && !wordTagList[tokenIndex].characters.contains(":") {
                    if let wordTagString = self.wordTagSelector?.findRandomWordTag(wordAtInputField) {
                        wordTagList[tokenIndex] = wordTagString
                        onWordTagChanged(wordTagString)
                    } else {
                        wordTagList[tokenIndex] = wordAtInputField
                    }
                }
            }
        } else if !isBackspacePressed && !characterBeforeCursor.isEmpty {
            // adding untagged word/character
            let wordAtInputField = getWordAtTokenIndex(tokenIndex)

            if tokenCount != lastTokenCount || wordTagList.isEmpty {
                wordTagList.insert(wordAtInputField, atIndex: tokenIndex)
            } else {
                wordTagList[tokenIndex] = wordAtInputField
            }
            
            attemptAssignWordTagDelayed(wordAtInputField, tokenIndex: tokenIndex)
        }
        
        BardLogger.log("ontextchange [post] wordTagList: \(wordTagList)")
        drawGenerateButton()

        lastTokenCount = tokenCount

        // always reset isBackspacePressed
        isBackspacePressed = false
    }
    
    func getWordAtTokenIndex(tokenIndex: Int) -> String {
        let words = inputTextField.text.characters.split{$0 == " "}.map(String.init)
        if tokenIndex < words.count {
            return words[tokenIndex].lowercaseString
        } else {
            return ""
        }
    }
    
    func getCharacterBeforeCursor() -> String {
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
            wordUnavailableLabel.text = "Unavailable: \(missingWords)"
            wordUnavailableLabel.hidden = false
        } else {
            wordUnavailableLabel.hidden = true
            wordUnavailableLabel.text = ""
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
    
    @IBAction func onKeyboardBtnClick(sender: UIButton) {
        if isKeyboardShown {
             inputTextField.resignFirstResponder()
        } else {
            //   inputTextField.endEditing(true)
            inputTextField.becomeFirstResponder()
        }
    }
    
    func keyboardWillAppear(notification: NSNotification){
        isKeyboardShown = true
        
        let info : NSDictionary = notification.userInfo!
        let keyboardHeight = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size.height
        let windowHeight = UIScreen.mainScreen().bounds.size.height
        let newVideoPlayerHeight = windowHeight - keyboardHeight!
                                                - controlsContainer.frame.size.height
        
        if keyboardHeight > wordTagCollectionView.frame.size.height {
            // keyboard covers input text field
            playerAspectRatioConstraint.setMultiplier(self.playerContainer.frame.size.width / newVideoPlayerHeight)
            wordTagCollectionView.hidden = true
            self.view.layoutIfNeeded()
        } else {
            wordTagCollectionView.hidden = true
        }
        
        
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        isKeyboardShown = false
        wordTagCollectionView.hidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextViewTextDidChangeNotification, object: inputTextField)
    }

    func initPreviewTimeline() {
        previewTimelineCollectionView.hidden = true
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
        
        if ((self.wordTagSelector?.setWordTag(wordTagString)) != nil) {
            onWordTagChanged(wordTagString)
        } else if wordTagString.characters.contains(":") {
            self.player.playFromBeginning()
            // highlight thumbnail even if same wordtagstring (to account for change in indexPath.row)
//            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PreviewTimelineCollectionViewCell
//            highlightImageView(cell)
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
        
        if ((self.wordTagSelector?.setWordTag(wordTagString, force: true)) != nil) {
            if lastTokenCount > tokenCountBeforeWordTagClick {
                wordTagList.insert(wordTagString, atIndex: self.currentWordTagListIndex)
            } else {
                wordTagList[self.currentWordTagListIndex] = wordTagString
            }
            BardLogger.log("wordTagClick - wordTagList is \(wordTagList)")
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
            if indexPath.row < self.wordTagStringList.count {
                // http://stackoverflow.com/a/38287614
                // background thread might not update/fill self.wordTagStringList fast enough
                // making it incur index out of bounds error
                let wordTagString = self.wordTagStringList[indexPath.row]
                let wordTagComponents = wordTagString.componentsSeparatedByString(":")
                
                if wordTagComponents.count > 0 {
                    let word = wordTagComponents[0]
                    self.sizingCell.textLabel.text = word
                }
            }
            
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

        // http://stackoverflow.com/questions/10781291/center-uiactivityindicatorview-in-a-uiimageview
        // http://stackoverflow.com/questions/17530659/uiactivityindicatorview-animation-delayed
        self.activityIndicator?.startAnimating()
        
        self.outputWordTagStrings = getWordTagStrings()
        let segmentUrls = self.outputWordTagStrings.map { wordTagString in
            segmentUrlFromWordTag(wordTagString)
            }.flatMap { $0 }
        
        self.outputPhrase = self.outputWordTagStrings.map { wordTagString in wordTagString.componentsSeparatedByString(":")[0]}.joinWithSeparator(" ")
        
        if self.outputPhrase.isEmpty {
            BardLogger.log("text is blank. type something")
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
                        BardLogger.log((error?.localizedDescription)!)
                    }
                    else if outputURL == nil {
                        BardLogger.log("failed to merge videos")
                    }
                    else {
                        Analytics.track("generateBardVideo",
                                    properties: ["wordTags" : self.outputWordTagStrings,
                                        "sceneToken" : self.scene?.token ?? "",
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
                    BardLogger.log("missing word \(word)")
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
        let originalSceneToken = scene.token.componentsSeparatedByString("@")[0]
        return "\(cdnPath)/segments/\(originalSceneToken)/\(tag).mp4"
        
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
//            initCharacterWordList()
        }
        
    }
    
    func initSceneWordList(selectedScene: Scene) {
        if selectedScene.wordList.isEmpty {
            BardClient.getSceneWordList(selectedScene.token, success: { value in
                let dict = (value as! [String:AnyObject])

                if let sceneWordList = dict["wordList"] as? String {
                    let realm = try! Realm()
                    try! realm.write {
                        selectedScene.wordList = sceneWordList
                    }
                    
                    // add to both scene dictionary and main dictionary (as it wasnt there before)
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
    
    
    @IBAction func unwindToEditor(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.sourceViewController as? SceneSelectViewController {
            self.originatingViewController = sourceViewController
            
            // reset dictionary
            self.wordTagStringList.removeAll()
            
            // set scene
            
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
        
        self.wordTagSelector?.setSceneWordTagMap(sceneWordTagMap)
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
        // HACK: at this point the bounds of player has been set (we can safely position the activityIndicator)
        if self.activityIndicator == nil {
            self.activityIndicator = Helper.addActivityIndicator(self.player.view)
        }
        
        // download video if not cached to disk yet
        Storage.saveRemoteVideoAsync(segmentUrl,
                                     activityIndicator: self.activityIndicator,
                                     completion: { filePath in
                                        
        
            let segmentFileUrl = NSURL(fileURLWithPath: filePath)
            self.playVideo(segmentFileUrl)
            
            // let previewTimeline draw thumbnails once mp4 has been downloaded
            self.previewTimelineCollectionView.reloadData()
            self.previewTimelineCollectionView.layoutIfNeeded()
            
            // once thumbnails are drawn, we can highlight/select them
            let indexPath = NSIndexPath(forRow: self.currentWordTagListIndex, inSection: 0)
            
//            var thumbnail = self.previewTimelineCollectionView.cellForItemAtIndexPath(indexPath) as? PreviewTimelineCollectionViewCell
            
            // if at first try thumbnail is nil, it means the cell item is currently not visible
            // try to scroll to that position to make it visibe, then re-attempt to fetch the thumbnail again
//            if thumbnail == nil {
//                // before we scroll some of previous cells outside of view, unhighlight them first
//                self.unHighlightPreviousImageView()
//                
//                UIView.animateWithDuration(0.3, animations: {
//                    self.previewTimelineCollectionView.scrollToItemAtIndexPath(indexPath,
//                        atScrollPosition: .CenteredHorizontally,
//                        animated: false)
//                }, completion: { (finished: Bool) -> Void in
//                    thumbnail = self.previewTimelineCollectionView.cellForItemAtIndexPath(indexPath) as? PreviewTimelineCollectionViewCell
//                    if thumbnail != nil {
//                        self.highlightImageView(thumbnail!)
//                    }
//                })
//                
//                
//            } else {
//                self.highlightImageView(thumbnail!)
//            }
        })

    }
    
    // source: 
    // https://github.com/ViccAlexander/Chameleon/blob/dde307d62cff1c0f9d65cf40a334c063db032c8f/Pod/Classes/Objective-C/UIColor%2BChameleon.m#L488
    func blackGradient(frame: CGRect, direction: String) -> UIColor {
        let backgroundGradientLayer = CAGradientLayer()
        backgroundGradientLayer.frame = frame
        let cgColors = [UIColor.blackColor().CGColor, UIColor.clearColor().CGColor]
        backgroundGradientLayer.colors = cgColors
        
        if direction == "right" {
            backgroundGradientLayer.startPoint = CGPointMake(0.0, 0.5)
            backgroundGradientLayer.endPoint   = CGPointMake(1.0, 0.5)
        } else if direction == "left" {
            backgroundGradientLayer.startPoint = CGPointMake(1.0, 0.5)
            backgroundGradientLayer.endPoint   = CGPointMake(0.0, 0.5)
        }
        
        //Convert our CALayer to a UIImage object
        UIGraphicsBeginImageContextWithOptions(backgroundGradientLayer.bounds.size,false, UIScreen.mainScreen().scale)
        backgroundGradientLayer.renderInContext(UIGraphicsGetCurrentContext()!)
        
        let backgroundColorImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return UIColor(patternImage: backgroundColorImage)
    }
    
    func addGradientsToNavigation() {
        if self.findPrevButton.backgroundColor == nil {
            self.findPrevButton.backgroundColor = blackGradient(self.findPrevButton.frame, direction: "right")
        }
        
        if self.findNextButton.backgroundColor == nil {
            self.findNextButton.backgroundColor = blackGradient(self.findNextButton.frame, direction: "left")
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
            
            addGradientsToNavigation()
            
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
//        self.sceneSelectButton.alpha = 0.4
        
        self.player = self.childViewControllers.last as! Player
        self.player.view.layer.hidden = false
        self.player.view.backgroundColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1.0)
        
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.player.view.addGestureRecognizer(tapGestureRecognizer)
        self.player.delegate = self
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
        

        // word unavailable error label
        wordUnavailableLabel = UILabelWithPadding(topInset: 2,leftInset: 2,bottomInset: 2,rightInset: 2)
        wordUnavailableLabel.textColor = UIColor.whiteColor()
        wordUnavailableLabel.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.8)
        wordUnavailableLabel.translatesAutoresizingMaskIntoConstraints = false
        wordUnavailableLabel.font = UIFont.systemFontOfSize(12)
        wordUnavailableLabel.hidden = true

        self.player.view.addSubview(wordUnavailableLabel)
        
        NSLayoutConstraint(item: wordUnavailableLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: wordUnavailableLabel, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.player.view, attribute: NSLayoutAttribute.TopMargin, multiplier: 1.0, constant: 10.0).active = true

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
        if self.wordTagSelector?.getWordTagVariantCount() == 1 {
            self.player.playFromBeginning()

        } else if let wordTagString = self.wordTagSelector?.findPrevWordTag() {
            if self.currentWordTagListIndex < self.wordTagList.count {
                self.wordTagList[self.currentWordTagListIndex] = wordTagString
                onWordTagChanged(wordTagString, withDelay: 0.5)
            }
        }
    }
    
    func onNextBtnClick() {
        if self.wordTagSelector?.getWordTagVariantCount() == 1 {
            self.player.playFromBeginning()
        } else if let wordTagString = self.wordTagSelector?.findNextWordTag() {
            if self.currentWordTagListIndex < self.wordTagList.count {
                self.wordTagList[self.currentWordTagListIndex] = wordTagString
                onWordTagChanged(wordTagString, withDelay: 0.5)
            }
        }
    }
    

    
    func playVideo(fileUrl: NSURL) {
        self.player.setUrl(fileUrl)
        self.player.playFromBeginning()
    }
    
    func shareSceneToFriend() {
        if let currentScene = self.scene {
            let sceneEditorUrl = Configuration.bardAccountBaseURL + "/scenes/" + currentScene.token + "/editor"
            let objectsToShare = [sceneEditorUrl]
            let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.presentViewController(activityViewController, animated: true, completion: nil)
        }
        
    }
    
    func addRemoveSceneToCollection() {
        
    }
    
    func copyLink() {
        if let currentScene = self.scene {
            let sceneEditorUrl = Configuration.bardAccountBaseURL + "/scenes/" + currentScene.token + "/editor"
            UIPasteboard.generalPasteboard().string = sceneEditorUrl
            Drop.down("Copied to clipboard", state: .Success, duration: 3)
        }
        
    }
    
    func showMoreOptions() {
        let alertController = UIAlertController(title: NSLocalizedString("More actions", comment: ""), message: nil, preferredStyle: .ActionSheet)
        
        let shareToFriendAction: UIAlertAction = UIAlertAction(title: "Share to Friend", style: .Default) { _ in
            self.shareSceneToFriend()
        }
        
        let addToCollectionAction: UIAlertAction = UIAlertAction(title: "Add to My Collection", style: .Default) { _ in
            self.addRemoveSceneToCollection()
        }
        
        let copyLinkAction: UIAlertAction = UIAlertAction(title: "Copy Link", style: .Default) { _ in
            self.copyLink()
        }
        
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { [weak self] _ in
            // do nothing will dismiss it
        }
        
//        alertController.addAction(addToCollectionAction)
        alertController.addAction(shareToFriendAction)
        alertController.addAction(copyLinkAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)

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
