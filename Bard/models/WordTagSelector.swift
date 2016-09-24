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
    var currentWord: String = ""
    var currentWordTagIndex: Int = 0
    
    let NEXT_DIRECTION = "next";
    let PREV_DIRECTION = "prev";
    
    init(wordTagMap: [String: [String]]) {
        self.wordTagMap = wordTagMap
    }
    
    func setWordTag(wordTagString: String) -> Bool {
        if !wordTagString.characters.contains(":") || wordTagString == getCurrentWordTagString() {
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
    
    func findRandomWordTag(word: String) -> String? {
        guard let wordTagList = self.wordTagMap[word] else {
            return nil
        }
        
        let randomIndex = Int(arc4random_uniform(UInt32(wordTagList.count)))
        
        self.currentWord = word
        self.currentWordTagIndex = randomIndex
        
        return wordTagList[randomIndex]
    }
    
    func findNextWordTag() -> String? {
        return findWordTag(self.currentWord, direction: NEXT_DIRECTION)
    }
    
    func findPrevWordTag() -> String? {
        return findWordTag(self.currentWord, direction: PREV_DIRECTION)
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