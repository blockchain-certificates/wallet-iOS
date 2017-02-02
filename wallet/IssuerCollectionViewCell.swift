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
            self.accessibilityLabel = issuerName
            if titleLabel != nil {
                titleLabel.text = issuerName
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.containerView.layer.masksToBounds = true
        self.containerView.layer.cornerRadius = Dimensions.issuerCornerRadius
        
        titleLabel.text = issuerName
        
        self.isAccessibilityElement = true
        self.accessibilityLabel = NSLocalizedString("Issuer", comment: "Accessibility label: Issuer collection cell")
        self.accessibilityTraits |= UIAccessibilityTraitButton
    }

    var certificateCount : Int {
        get {
            var count = 0
            if let string = certificateCountLabel.text,
                let possibleCount = Int(string) {
                count = possibleCount
            }
            return count
        }
        set {
            certificateCountLabel.text = "\(newValue)"
        }
    }
    

}
