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
    @IBOutlet weak var containerView: UIView!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        containerView.backgroundColor = selected ? Style.Color.C10 : Style.Color.C1
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        containerView.backgroundColor = highlighted ? Style.Color.C10 : Style.Color.C1
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
                
        certificateTitleLabel.text = title
        certificateSubtitleLabel.text = subtitle
        
        containerView.layer.cornerRadius = Style.Measure.cornerRadius
        containerView.layer.borderColor = Style.Color.C8.cgColor
        containerView.layer.borderWidth = 1
        
        selectedBackgroundView = UIView()
    }
    
}
