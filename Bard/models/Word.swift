//
//  Word.swift
//  Bard
//
//  Created by Reginald Tan on 2017-04-14.
//  Copyright © 2017 ROP Labs. All rights reserved.
//

import Foundation


class Word : Searchable {
    let word : String
    init(_ word: String) {
        self.word = word
    }
    
    // From Searchable protocol
    func keywords() -> [String] {
        return [word]
    }
    
    // Hashable
    var hashValue: Int { return word.hashValue }
    
}

func == (lhs: Word, rhs: Word) -> Bool {
    return lhs.word == rhs.word
}
