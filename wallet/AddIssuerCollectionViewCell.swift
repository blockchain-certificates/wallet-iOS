//
//  AddIssuerCollectionViewCell.swift
//  wallet
//
//  Created by Chris Downie on 12/9/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit

class AddIssuerCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var dottedLineImageView: UIImageView!
    @IBOutlet weak var containerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = Dimensions.issuerCornerRadius
        
        dottedLineImageView.tintColor = Colors.brandColor
    }

}
