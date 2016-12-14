//
//  CertificateTitleTableViewCell.swift
//  wallet
//
//  Created by Chris Downie on 12/14/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit

class CertificateTitleTableViewCell: UITableViewCell {
    let missingSubtitleText = "No subtitle provided"
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
            updateSubtitleLabel()
        }
    }

    @IBOutlet weak var certificateTitleLabel: UILabel!
    @IBOutlet weak var certificateSubtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.accessoryType = .disclosureIndicator
        
        certificateTitleLabel.text = title
        certificateTitleLabel.textColor = primaryTextColor
        
        updateSubtitleLabel()
    }
    
    func updateSubtitleLabel() {
        if let subtitle = subtitle {
            certificateSubtitleLabel.text = subtitle
            certificateSubtitleLabel.textColor = primaryTextColor
        } else {
            certificateSubtitleLabel.text = missingSubtitleText
            certificateSubtitleLabel.textColor = Colors.placeholderTextColor
        }
    }
}
