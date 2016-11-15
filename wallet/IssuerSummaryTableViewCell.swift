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
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
