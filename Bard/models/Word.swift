//
//  Word.swift
//  Bard
//
//  Created by Reginald Tan on 2017-04-14.
//  Copyright © 2017 ROP Labs. All rights reserved.
//

import Foundation


class Word : NSObject, Searchable {
    let word : String
    init(_ word: String) {
        self.word = word
    }
    
    // From Searchable protocol
    func keywords() -> [String] {
        return [word]
    }
    
    // Hashable
    override var hashValue: Int { return word.hashValue }
    override var description: String { return word }
    
}

func == (lhs: Word, rhs: Word) -> Bool {
    return lhs.word == rhs.word
}
