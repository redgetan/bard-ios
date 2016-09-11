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
}