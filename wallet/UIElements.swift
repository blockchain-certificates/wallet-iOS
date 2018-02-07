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
class LabelC3T3S : LabelC3T3B {
    override var color: UIColor { return Style.Color.C3 }
}
