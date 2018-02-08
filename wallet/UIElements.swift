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
    func commonInit()
}

class ButtonBase : UIButton {

    var textColor : UIColor { return .white }
    var textColorHighlighted : UIColor { return .white }
    var textColorDisabled : UIColor { return Style.Color.C7 }
    var strokeColor : UIColor { return .white }
    var strokeColorHighlighted : UIColor { return .white }
    var strokeColorDisabled : UIColor { return Style.Color.C7 }
    var fillColor : UIColor { return .white }
    var fillColorHighlighted : UIColor { return .white }
    var fillColorDisabled : UIColor { return .clear }

    func commonInit() {
        let edgeInsets : CGFloat = 20
        contentEdgeInsets = UIEdgeInsets(top: edgeInsets, left: edgeInsets, bottom: edgeInsets, right: edgeInsets)
        
        layer.borderWidth = Style.Measure.stroke
        layer.cornerRadius = Style.Measure.cornerRadius
        layer.borderColor = strokeColor.cgColor
        
        titleLabel?.font = Style.Font.T3S
        setTitleColor(textColor, for: .normal)
        setTitleColor(textColorHighlighted, for: .highlighted)
        setTitleColor(textColorDisabled, for: .disabled)
        
        isHighlighted = false
        isEnabled = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? fillColorHighlighted : fillColor
            layer.borderColor = (isHighlighted ? strokeColorHighlighted : strokeColor).cgColor
            layer.cornerRadius = Style.Measure.cornerRadius
        }
    }

    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? fillColor : fillColorDisabled
            layer.borderColor = (isEnabled ? strokeColor : strokeColorDisabled).cgColor
            layer.cornerRadius = Style.Measure.cornerRadius
        }
    }

}


@IBDesignable
class PrimaryButton : ButtonBase {
    
    override var textColor : UIColor { return Style.Color.C1 }
    override var textColorHighlighted : UIColor { return Style.Color.C6_40 }

    override var strokeColor : UIColor { return Style.Color.C4 }
    override var strokeColorHighlighted : UIColor { return Style.Color.C11_80 }

    override var fillColor : UIColor { return Style.Color.C4 }
    override var fillColorHighlighted : UIColor { return Style.Color.C11_80 }

}

@IBDesignable
class SecondaryButton : ButtonBase {
    
    override var textColor : UIColor { return Style.Color.C4 }
    override var textColorHighlighted : UIColor { return Style.Color.C11 }
    
    override var strokeColor : UIColor { return Style.Color.C4 }
    override var strokeColorHighlighted : UIColor { return Style.Color.C4_80 }
    
    override var fillColor : UIColor { return .clear }
    override var fillColorHighlighted : UIColor { return Style.Color.C4_80 }

}

@IBDesignable
class CheckmarkButton : SecondaryButton {
    var checkmark = UIImageView()
    var checked : Bool = true {
        didSet {
            checkmark.isHidden = !checked
        }
    }
    
    override func commonInit() {
        super.commonInit()
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        checkmark.image = #imageLiteral(resourceName: "icon_check")
        addSubview(checkmark)
        
        checkmark.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Style.Measure.buttonCheckPadding).isActive = true
        checkmark.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

}
