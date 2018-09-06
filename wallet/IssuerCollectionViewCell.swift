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

    override var isSelected: Bool {
        didSet {
            containerView.backgroundColor = isSelected ? Style.Color.C10 : Style.Color.C1
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            containerView.backgroundColor = isHighlighted ? Style.Color.C10 : Style.Color.C1
        }
    }
    
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
        containerView.layer.cornerRadius = Style.Measure.cornerRadius
        
        titleLabel.text = issuerName
        titleLabel.backgroundColor = .clear
        
        isAccessibilityElement = true
        accessibilityLabel = Localizations.Issuer
        accessibilityTraits |= UIAccessibilityTraitButton
        
    }

    var certificateCount = 0 {
        didSet {
            if certificateCount == 0 { //TODO: Localize
                certificateCountLabel.text = "No credentials"
            } else if certificateCount == 1 {
                certificateCountLabel.text = "1 credential"
            } else {
                certificateCountLabel.text = "\(certificateCount) credentials"
            }
        }
    }
    

}
