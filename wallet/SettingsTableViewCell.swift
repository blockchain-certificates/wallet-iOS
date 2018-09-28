//
//  SettingsTableViewCell.swift
//  certificates
//
//  Created by Michael Shin on 9/28/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    @IBOutlet weak var label: LabelC3T3S!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        isAccessibilityElement = true
    }
}
