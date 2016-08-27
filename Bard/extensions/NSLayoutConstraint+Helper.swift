//
//  NSLayoutConstraint+Helper.swift
//  Bard
//
//  Created by Reginald Tan on 2016-08-27.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import Foundation

// http://stackoverflow.com/a/33003217

extension NSLayoutConstraint {
    
    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {
        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        
        newConstraint.priority = self.priority
        
        NSLayoutConstraint.deactivateConstraints([self])
        NSLayoutConstraint.activateConstraints([newConstraint])
        return newConstraint
    }
}