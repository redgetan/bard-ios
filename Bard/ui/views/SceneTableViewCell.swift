//
//  SceneTableViewCell.swift
//  Bard
//
//  Created by Reginald Tan on 2016-07-28.
//  Copyright © 2016 ROP Labs. All rights reserved.
//

import UIKit

class SceneTableViewCell: UITableViewCell {

    @IBOutlet weak var sceneNameLabel: UILabel!

    @IBOutlet weak var sceneOwnerLabel: UILabel!
    @IBOutlet weak var sceneImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
