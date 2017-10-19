//
//  LabeledTableViewCell.swift
//  wallet
//
//  Created by Chris Downie on 1/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit

class LabeledTableViewCell: UITableViewCell {
    let titleLabel : UILabel
    let contentLabel : UILabel

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.thin)
        
        contentLabel = UILabel()
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.numberOfLines = 0
        contentLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        
        let views : [String : UILabel] = [
            "titleLabel": titleLabel,
            "contentLabel": contentLabel,
        ]
        
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[titleLabel]-[contentLabel]-|", options: .alignAllCenterX, metrics: nil, views: views)
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-[titleLabel]-|", options: .alignAllCenterX, metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-[contentLabel]-|", options: .alignAllCenterX, metrics: nil, views: views))
        
        NSLayoutConstraint.activate(constraints)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        print("\n\n\nawoke\n")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
