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
        adjustsFontForContentSizeCategory = true
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
class LabelC1T4S : LabelC3T3B {
    override var labelFont: UIFont { return Style.Font.T4S }
}

@IBDesignable
class LabelC3T3S : LabelC6T3S {
    override var color: UIColor { return Style.Color.C3 }
}

@IBDesignable
class LabelC3T4S : LabelC3T3S {
    override var labelFont: UIFont { return Style.Font.T4S }
}

@IBDesignable
class LabelC6T3R : LabelC6T3S {
    override var labelFont: UIFont { return Style.Font.T3R }
}

@IBDesignable
class LabelC6T2R : LabelC6T3S {
    override var labelFont: UIFont { return Style.Font.T2R }
}

@IBDesignable
class LabelC7T2S : LabelC6T3S {
    override var labelFont: UIFont { return Style.Font.T2S }
    override var color: UIColor { return Style.Color.C7 }
}

@IBDesignable
class LabelC7T4S : LabelC7T2S {
    override var labelFont: UIFont { return Style.Font.T4S }
}

@IBDesignable
class LabelC7T2R : LabelC7T2S {
    override var labelFont: UIFont { return Style.Font.T2R }
}

@IBDesignable
class LabelC7T1R : LabelC7T2S {
    override var labelFont: UIFont { return Style.Font.T1R }
}

class LabelC5T2B : LabelC3T3B {
    override var labelFont: UIFont { return Style.Font.T2B }
    override var color: UIColor { return Style.Color.C5 }
}

class LabelC7T3S : LabelC6T3S {
    override var color: UIColor { return Style.Color.C7 }
}

class LabelC6T3B : LabelC6T3S {
    override var labelFont: UIFont { return Style.Font.T3B }
}

class LabelC9T2B : LabelC7T2S {
    override var labelFont: UIFont { return Style.Font.T2B }
    override var color: UIColor { return Style.Color.C9 }
}

class LabelC6T2B : LabelC5T2B {
    override var color: UIColor { return Style.Color.C6 }
}

class LabelC3T2B : LabelC3T3B {
    override var labelFont: UIFont { return Style.Font.T2B }
}

class LabelC12T1R : LabelC3T3B {
    override var labelFont: UIFont { return Style.Font.T1R }
    override var color: UIColor { return Style.Color.C12 }
}

class LabelC3T2BNoScale : LabelC3T2B {
    override var labelFont: UIFont { return Style.Font.T2B_NoScale }
    override var color: UIColor { return Style.Color.C3 }
    override func commonInit() {
        super.commonInit()
        adjustsFontForContentSizeCategory = false
        adjustsFontSizeToFitWidth = true
    }
}

class LabelC7T1RNoScale : LabelC3T2BNoScale {
    override var labelFont: UIFont { return Style.Font.T1R_NoScale }
    override var color: UIColor { return Style.Color.C7 }
}

// MARK: - Buttons

protocol Button {
    func commonInit()
}

class ButtonBase : UIButton {

    var textColor : UIColor { return .white }
    var textColorHighlighted : UIColor { return .white }
    var textColorDisabled : UIColor { return Style.Color.C12 }
    var strokeColor : UIColor { return .white }
    var strokeColorHighlighted : UIColor { return .white }
    var strokeColorDisabled : UIColor { return Style.Color.C12 }
    var fillColor : UIColor { return .white }
    var fillColorHighlighted : UIColor { return .white }
    var fillColorDisabled : UIColor { return .clear }
    var titleFont : UIFont { return Style.Font.T3S }

    func commonInit() {
        let edgeInsets : CGFloat = 20
        contentEdgeInsets = UIEdgeInsets(top: edgeInsets, left: edgeInsets, bottom: edgeInsets, right: edgeInsets)
        
        layer.borderWidth = Style.Measure.stroke
        layer.cornerRadius = Style.Measure.cornerRadius
        layer.borderColor = strokeColor.cgColor
        
        titleLabel?.font = titleFont
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.adjustsFontSizeToFitWidth = true
        setTitleColor(textColor, for: .normal)
        setTitleColor(textColorHighlighted, for: .highlighted)
        setTitleColor(textColorDisabled, for: .disabled)

        imageView?.contentMode = .center
        imageView?.clipsToBounds = false
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)
        
        let height = heightAnchor.constraint(equalToConstant: Style.Measure.heightButtonLarge)
        height.priority = UILayoutPriority(rawValue: 900)
        height.isActive = true
        
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
    
    override var textColor : UIColor { return Style.Color.C3 }
    override var textColorHighlighted : UIColor { return Style.Color.C3 }
    override var textColorDisabled : UIColor { return Style.Color.C12 }

    override var strokeColor : UIColor { return Style.Color.C14 }
    override var strokeColorHighlighted : UIColor { return Style.Color.C4 }
    override var strokeColorDisabled : UIColor { return Style.Color.C8 }

    override var fillColor : UIColor { return Style.Color.C14 }
    override var fillColorHighlighted : UIColor { return Style.Color.C4 }
    override var fillColorDisabled : UIColor { return Style.Color.C8 }

}

@IBDesignable
class HomeSecondaryButton : ButtonBase {
    
    override var textColor : UIColor { return Style.Color.C14 }
    override var textColorHighlighted : UIColor { return Style.Color.C14 }
    
    override var strokeColor : UIColor { return Style.Color.C14 }
    override var strokeColorHighlighted : UIColor { return Style.Color.C4 }
    
    override var fillColor : UIColor { return Style.Color.C3 }
    override var fillColorHighlighted : UIColor { return Style.Color.C3 }
    
}


@IBDesignable
class SecondaryButton : ButtonBase {
    
    override var textColor : UIColor { return Style.Color.C3 }
    override var textColorHighlighted : UIColor { return Style.Color.C3 }
    
    override var strokeColor : UIColor { return Style.Color.C14 }
    override var strokeColorHighlighted : UIColor { return Style.Color.C4 }
    
    override var fillColor : UIColor { return .clear }
    override var fillColorHighlighted : UIColor { return Style.Color.C4 }
}

@IBDesignable
class DialogButton : SecondaryButton {
    
    override var textColor : UIColor { return Style.Color.C3 }
    override var textColorHighlighted : UIColor { return Style.Color.C3 }
    
    override var strokeColor : UIColor { return Style.Color.C14 }
    override var strokeColorHighlighted : UIColor { return Style.Color.C4 }
    
    override var fillColor : UIColor { return .clear }
    override var fillColorHighlighted : UIColor { return Style.Color.C4 }
    
    override var titleFont : UIFont { return Style.Font.T2S }
}

@IBDesignable
class TertiaryButton : SecondaryButton {
    override var textColorHighlighted : UIColor { return Style.Color.C3 }
    override var strokeColor : UIColor { return .clear }
    override var strokeColorHighlighted : UIColor { return .clear }

    override var fillColor : UIColor { return .clear }
    override var fillColorHighlighted : UIColor { return .clear }

}

@IBDesignable
class DangerButton : SecondaryButton {
    
    override var textColor : UIColor { return Style.Color.C9 }
    override var textColorHighlighted : UIColor { return Style.Color.C3 }
    
    override var strokeColor : UIColor { return Style.Color.C8 }
    override var strokeColorHighlighted : UIColor { return Style.Color.C9 }
    
    override var fillColor : UIColor { return .clear }
    override var fillColorHighlighted : UIColor { return Style.Color.C9 }
    
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
        
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)

    }
}

@IBDesignable
class CredentialActionButton : ButtonBase {
    
    override var textColor : UIColor { return Style.Color.C3 }
    override var textColorHighlighted : UIColor { return Style.Color.C3 }
    
    override var fillColor : UIColor { return .white }
    override var fillColorHighlighted : UIColor { return Style.Color.C10 }
    
    override func commonInit() {
        super.commonInit()
        layer.cornerRadius = 5
        clipsToBounds = true
        titleLabel?.font = Style.Font.T2S
        
        imageEdgeInsets = UIEdgeInsets(top: 0.0, left: -2.0, bottom: 0.0, right: 0.0)
        titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: -2.0)
        contentEdgeInsets = UIEdgeInsets.zero
    }
}

/// Sets the background of the image view to the top-left pixel of its image
//@IBDesignable
class FullBleedImageView : UIImageView {
    override var image: UIImage? {
        didSet {
            guard let image = image else { return }
            backgroundColor = image.color(at: .zero)
            
        }
    }
}


class ClosureSleeve {
    let closure: ()->()
    
    init (_ closure: @escaping ()->()) {
        self.closure = closure
    }
    
    @objc func invoke () {
        closure()
    }
}

extension UIControl {
    func onTouchUpInside(_ closure: @escaping ()->()) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: .touchUpInside)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

extension UIView {
    class func fromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}

class NavigationController: UINavigationController {
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    func commonInit() {
        //navigationBar.backIndicatorImage = UIImage(named: "icon_back")
        //navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "icon_back")
        styleDefault()
    }
}

extension UINavigationController {
    func styleDefault() {
        UIApplication.shared.statusBarStyle = .lightContent
        navigationBar.titleTextAttributes =
            [NSAttributedStringKey.font: Style.Font.T4B,
             NSAttributedStringKey.foregroundColor: Style.Color.C1]
        
        navigationBar.tintColor = Style.Color.C1
        navigationBar.barTintColor = Style.Color.C3
        navigationBar.isTranslucent = false
    }
    
    func styleAlternate() {
        UIApplication.shared.statusBarStyle = .default
        navigationBar.titleTextAttributes =
            [NSAttributedStringKey.font: Style.Font.T4B,
             NSAttributedStringKey.foregroundColor: Style.Color.C3]
        
        navigationBar.tintColor = Style.Color.C3
        navigationBar.barTintColor = Style.Color.C1
        navigationBar.isTranslucent = false
    }
    
    func styleHidden() {
        UIApplication.shared.statusBarStyle = .lightContent
        navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationBar.shadowImage = UIImage()
    }
}
