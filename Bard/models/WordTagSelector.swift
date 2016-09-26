//
//  WordTagSelector.swift
//  Bard
//
//  Created by Reginald Tan on 2016-09-23.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation

public class WordTagSelector {
    var wordTagMap: [String: [String]] = [String: [String]]()
    
    // similar map as wordTagMap but filtered to specific scene
    // when using sceneeditor (user selected specific scene), this is used to fetch wordtags
    var sceneWordTagMap: [String: [String]] = [String: [String]]()

    var currentWord: String = ""
    var currentWordTagIndex: Int = 0
    
    let NEXT_DIRECTION = "next";
    let PREV_DIRECTION = "prev";
    
    init(wordTagMap: [String: [String]]) {
        self.wordTagMap = wordTagMap
    }
    
    func setWordTag(wordTagString: String, force: Bool? = false) -> Bool {
        if !force! && (!wordTagString.characters.contains(":") || wordTagString == getCurrentWordTagString()) {
            return false
        }
        
        
        let word = wordTagString.componentsSeparatedByString(":")[0]
        if let wordTagList = self.wordTagMap[word] {
            self.currentWord = word
            self.currentWordTagIndex = wordTagList.indexOf(wordTagString)!
        }
        
        return true
    }
    
    func getCurrentWordTagString() -> String {
        if currentWord.isEmpty {
            return ""
        } else {
            return self.wordTagMap[self.currentWord]![self.currentWordTagIndex]
        }
    }
    
    func setSceneWordTagMap(sceneWordTagMap: [String: [String]]) {
        self.sceneWordTagMap = sceneWordTagMap
    }
    
    func findRandomWordTag(word: String) -> String? {
        var randomIndex: Int
        var wordTagString: String
        
        // get global word variants of word
        guard let wordTagList = self.wordTagMap[word] else {
            return nil
        }
        
        if self.sceneWordTagMap.count > 0 {
            // get scene specific word variants of word
            if let sceneWordTagList = self.sceneWordTagMap[word] {
                randomIndex = Int(arc4random_uniform(UInt32(sceneWordTagList.count)))
                wordTagString = sceneWordTagList[randomIndex]
            } else {
                // if sceneWordTagMap fails to find appropriate word, fall back to general wordTagMap
                randomIndex = Int(arc4random_uniform(UInt32(wordTagList.count)))
                wordTagString = wordTagList[randomIndex]
            }
        } else {
            randomIndex = Int(arc4random_uniform(UInt32(wordTagList.count)))
            wordTagString = wordTagList[randomIndex]
        }
        
        self.currentWord = word
        self.currentWordTagIndex = wordTagList.indexOf(wordTagString)!
        
        return wordTagString
    }
    
    func findNextWordTag() -> String? {
        return findWordTag(self.currentWord, direction: NEXT_DIRECTION)
    }
    
    func findPrevWordTag() -> String? {
        return findWordTag(self.currentWord, direction: PREV_DIRECTION)
    }
    
    func getWordTagVariantCount() -> Int {
        if let wordTagList = self.wordTagMap[self.currentWord] {
            return wordTagList.count
        } else {
            return 0
        }
    }
    
    func findWordTag(word: String, direction: String) -> String? {
        if isWordNotInDatabase(word) {
            return nil
        }

        self.currentWord = word
        
        if isWordChanged(word) {
            resetWordTagIndex()
        } else {
            updateWordTagIndex(word, direction: direction)
        }
        
        let wordTagString = self.wordTagMap[word]![self.currentWordTagIndex]
        return wordTagString
    }
    
    func resetWordTagIndex() {
        self.currentWordTagIndex = 0
    }
    
    func updateWordTagIndex(word: String, direction: String) {
        if direction == NEXT_DIRECTION {
            self.currentWordTagIndex += 1
        } else if direction == PREV_DIRECTION {
            self.currentWordTagIndex -= 1
        }
        
        if currentWordTagIndex < 0 {
            self.currentWordTagIndex = wordTagMap[word]!.count - 1
        } else if currentWordTagIndex > wordTagMap[word]!.count - 1 {
            self.currentWordTagIndex = 0
        }
    }
    
    func isWordChanged(word: String) -> Bool {
        return self.currentWord != word
    }
    
    func isWordNotInDatabase(word: String) -> Bool {
        return self.wordTagMap[word] == nil
    }
    
}