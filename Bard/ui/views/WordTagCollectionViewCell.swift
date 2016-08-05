//
//  WordTagCollectionViewCell.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-30.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit

class WordTagCollectionViewCell: UICollectionViewCell {
    var textLabel: UILabelWithPadding!
    var wordTagString = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.contentView.layer.borderWidth = 1
        
        self.textLabel = UILabelWithPadding()
        self.textLabel.translatesAutoresizingMaskIntoConstraints = false
        self.textLabel.font = UIFont.systemFontOfSize(16)
            self.textLabel.textColor = UIColor.grayColor()
        self.contentView.addSubview(self.textLabel)

        // http://stackoverflow.com/a/26181982
        
        let horizontalConstraint = NSLayoutConstraint(item: self.textLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        
        let verticalConstraint = NSLayoutConstraint(item: self.textLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)

        self.contentView.addConstraint(horizontalConstraint)
        self.contentView.addConstraint(verticalConstraint)

    }
    
    override func intrinsicContentSize() -> CGSize {
        return self.textLabel.intrinsicContentSize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
