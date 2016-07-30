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
        
        self.contentView.layer.borderColor = UIColor.grayColor().CGColor
        self.contentView.layer.borderWidth = 1
        
        self.textLabel = UILabelWithPadding()
        self.textLabel.translatesAutoresizingMaskIntoConstraints = false
        self.textLabel.font = UIFont.systemFontOfSize(14)
            self.textLabel.textColor = UIColor.grayColor()
        self.contentView.addSubview(self.textLabel)

        // http://stackoverflow.com/a/36263784/803865
        
//        let margins = self.contentView.layoutMarginsGuide
//        self.textLabel.leadingAnchor.constraintEqualToAnchor(margins.leadingAnchor, constant: 5).active = true
//        self.textLabel.trailingAnchor.constraintEqualToAnchor(margins.trailingAnchor, constant: 5).active = true
//        self.textLabel.topAnchor.constraintEqualToAnchor(margins.topAnchor, constant: 5).active = true
//        self.textLabel.bottomAnchor.constraintEqualToAnchor(margins.bottomAnchor, constant: 5).active = true
        self.textLabel.centerXAnchor.constraintEqualToAnchor(self.contentView.centerXAnchor).active = true
        self.textLabel.centerYAnchor.constraintEqualToAnchor(self.contentView.centerYAnchor).active = true


    }
    
    override func intrinsicContentSize() -> CGSize {
        return self.textLabel.intrinsicContentSize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
