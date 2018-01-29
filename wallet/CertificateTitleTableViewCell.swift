//
//  CertificateTitleTableViewCell.swift
//  wallet
//
//  Created by Chris Downie on 12/14/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit

class CertificateTitleTableViewCell: UITableViewCell {
    let primaryTextColor = UIColor.black
    
    public var title : String? {
        didSet {
            if certificateTitleLabel != nil {
                certificateTitleLabel.text = title
            }
        }
    }
    public var subtitle : String? {
        didSet {
            if certificateSubtitleLabel != nil {
                certificateSubtitleLabel.text = subtitle
            }
        }
    }

    @IBOutlet weak var certificateTitleLabel: UILabel!
    @IBOutlet weak var certificateSubtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        accessoryType = .disclosureIndicator
        
        certificateTitleLabel.text = title
        certificateTitleLabel.textColor = primaryTextColor
        certificateSubtitleLabel.text = subtitle
        certificateSubtitleLabel.textColor = primaryTextColor
    }
    
}
