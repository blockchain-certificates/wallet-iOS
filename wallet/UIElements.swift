//
//  UIElements.swift
//  certificates
//
//  Created by Quinn McHenry on 2/7/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import UIKit

// MARK: - Labels

@IBDesignable
class LabelC3T3B : UILabel {
    var labelFont: UIFont { return Style.Font.T3B }
    var color: UIColor { return Style.Color.C3 }

    func commonInit() {
        font = labelFont
        textColor = color
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
}

@IBDesignable
class LabelC3T5S : LabelC3T3B {
    override var labelFont: UIFont { return Style.Font.T5S }
}

@IBDesignable
class LabelC6T3S : LabelC3T3B {
    override var labelFont: UIFont { return Style.Font.T3S }
    override var color: UIColor { return Style.Color.C6 }
}

@IBDesignable
class LabelC1T3S : LabelC3T3B {
    override var labelFont: UIFont { return Style.Font.T3S }
    override var color: UIColor { return Style.Color.C1 }
}

@IBDesignable
class LabelC3T3S : LabelC6T3S {
    override var color: UIColor { return Style.Color.C3 }
}


// MARK: - Buttons

protocol Button {
    var textColor : UIColor {get}
    var strokeColor : UIColor {get}
    var fillColor : UIColor {get}
    func commonInit()
}

extension Button where Self : UIButton {
    
    func commonInit() {
        let edgeInsets : CGFloat = 20
        contentEdgeInsets = UIEdgeInsets(top: edgeInsets, left: edgeInsets, bottom: edgeInsets, right: edgeInsets)
        
        layer.borderWidth = Style.Measure.stroke
        layer.cornerRadius = Style.Measure.cornerRadius
        layer.borderColor = strokeColor.cgColor
        
        titleLabel?.font = Style.Font.T3S
        setTitleColor(textColor, for: .normal)
        setTitleColor(textColor, for: .selected)
        setTitleColor(textColor, for: .highlighted)
        setTitleColor(textColor, for: .focused)
        
        backgroundColor = fillColor
    }
    
}


@IBDesignable
class PrimaryButton : UIButton, Button {
    
    let textColor = Style.Color.C1
    let strokeColor = Style.Color.C4
    let fillColor = Style.Color.C4
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
}

@IBDesignable
class SecondaryButton : UIButton, Button {
    
    let textColor = Style.Color.C4
    let strokeColor = Style.Color.C4
    let fillColor = UIColor.clear
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
}

@IBDesignable
class CheckmarkButton : SecondaryButton {
    var checkmark : UIImageView!
    var checked : Bool = true {
        didSet {
            checkmark.isHidden = !checked
        }
    }
    
    func commonInit() {
        super.commonInit()
        checkmark.image = #imageLiteral(resourceName: "icon_check")
        addSubview(checkmark)
        checkmark.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Style.Measure.buttonCheckPadding).isActive = true
        checkmark.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    override init(frame: CGRect) {
        checkmark = UIImageView()
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        checkmark = UIImageView()
        super.init(coder: aDecoder)
        commonInit()
    }
}
