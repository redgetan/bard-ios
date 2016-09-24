//
//  String+Helper.swift
//  Bard
//
//  Created by Reginald Tan on 2016-09-11.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation

extension String {
    func wordRanges() -> [NSRange] {
        
        let range = Range<String.Index>(self.startIndex..<self.endIndex)
        var ranges = [NSRange]()
        
        self.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByWords) { (substring, substringRange, enclosingRange, _) -> () in
            let wordLocation = substringRange.startIndex.distanceTo(self.startIndex)
            let wordLength   = substringRange.endIndex.distanceTo(substringRange.startIndex)
            ranges.append(NSMakeRange(wordLocation, wordLength))
        }
        
        return ranges
    }
    
    func wordPositions() -> [(Int, Int)] {
        
        let range = Range<String.Index>(self.startIndex..<self.endIndex)
        var ranges = [(Int, Int)]()
        let textStartIndex = self.startIndex
        
        self.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByWords) { (substring, substringRange, enclosingRange, _) -> () in
            let wordLocation      = textStartIndex.distanceTo(substringRange.startIndex)
            let wordEndLocation   = textStartIndex.distanceTo(substringRange.endIndex)
            ranges.append((wordLocation, wordEndLocation))
        }
        
        return ranges
    }
}