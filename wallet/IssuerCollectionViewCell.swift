//
//  IssuerCollectionViewCell.swift
//  wallet
//
//  Created by Chris Downie on 10/26/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit

class IssuerCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak var certificateCountLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

    var issuerName : String? {
        didSet {
            accessibilityLabel = issuerName
            if titleLabel != nil {
                titleLabel.text = issuerName
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = Dimensions.issuerCornerRadius
        
        titleLabel.text = issuerName
        
        isAccessibilityElement = true
        accessibilityLabel = NSLocalizedString("Issuer", comment: "This describes the issuer cell in the collection view. It's an accessibility label read aloud for users with VoiceOver.")
        accessibilityTraits |= UIAccessibilityTraitButton
    }

    var certificateCount = 0 {
        didSet {
            if certificateCount == 0 {
                certificateCountLabel.text = "No credentials"
            } else if certificateCount == 1 {
                certificateCountLabel.text = "1 credential"
            } else {
                certificateCountLabel.text = "\(certificateCount) credentials"
            }
        }
    }
    

}
