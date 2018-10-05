//
//  IssuerSummaryTableViewCell.swift
//  wallet
//
//  Created by Chris Downie on 11/14/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit

class IssuerSummaryTableViewCell: UITableViewCell {
    @IBOutlet weak var issuerImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var issuerDescription : String? {
        didSet {
            updateDescriptionLabel()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        updateDescriptionLabel()
    }
    
    func updateDescriptionLabel() {
        if let description = issuerDescription {
            descriptionLabel.text = description
        } else {
            descriptionLabel.text = Localizations.IssuerMissingDescription
        }
    }
}
