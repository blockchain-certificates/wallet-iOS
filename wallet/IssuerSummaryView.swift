//
//  IssuerSummaryView.swift
//  wallet
//
//  Created by Chris Downie on 12/19/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit

class IssuerSummaryView: UIView {
    var issuer: ManagedIssuer? {
        didSet {
            updateIssuerData()
        }
    }
    
    private var iconView : UIImageView!
    private var descriptionLabel : UILabel!
    
    convenience init(issuer: ManagedIssuer) {
        self.init(frame: .zero)
        self.issuer = issuer
        updateIssuerData()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = Style.Color.C1
        
        iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconView)
        addSubview(descriptionLabel)
        
        let views : [String: UIView] = [
            "iconView": iconView,
            "descriptionLabel": descriptionLabel
        ]
        
        let constraints = [
            NSLayoutConstraint(item: iconView, attribute: .width, relatedBy: .equal, toItem: iconView, attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: iconView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .leftMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: descriptionLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .leftMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: descriptionLabel, attribute: .right, relatedBy: .equal, toItem: self, attribute: .rightMargin, multiplier: 1, constant: 0)
        ]
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[iconView(==100)]-[descriptionLabel]-20-|", options: .alignAllLeft, metrics: nil, views: views)
        
        NSLayoutConstraint.activate(constraints)
        NSLayoutConstraint.activate(verticalConstraints)
    }
    
    func updateIssuerData() {
        guard let realIssuer = issuer?.issuer else {
            return
        }
        
        iconView.image = UIImage(data: realIssuer.image)
        descriptionLabel.text = issuer?.issuerDescription
    }
}
