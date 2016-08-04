//
//  UILabelWithPadding.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-30.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit

// http://stackoverflow.com/a/34982362/803865

class UILabelWithPadding: UILabel {

    let topInset = CGFloat(5.0)
    let bottomInset = CGFloat(5.0)
    let leftInset = CGFloat(10.0)
    let rightInset = CGFloat(10.0)
    
    override func drawTextInRect(rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override func intrinsicContentSize() -> CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize()
        intrinsicSuperViewContentSize.height += topInset + bottomInset
        intrinsicSuperViewContentSize.width += leftInset + rightInset
        return intrinsicSuperViewContentSize
    }
}
