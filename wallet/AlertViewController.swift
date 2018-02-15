//
//  AlertViewController.swift
//  certificates
//
//  Created by Quinn McHenry on 2/12/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import Foundation


class AlertViewController : UIViewController {
 
    enum Icon {
        case success
        case failure
        case warning
        case verifying
        
        var image: UIImage {
            switch self {
            case .success:
                return #imageLiteral(resourceName: "icon_sucess")
            case .failure:
                return #imageLiteral(resourceName: "icon_failure")
            case .warning:
                return #imageLiteral(resourceName: "icon_warning")
            case .verifying:
                return #imageLiteral(resourceName: "icon_loading")
            }
        }
    }
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var buttonStack: UIStackView!
    var buttons = [UIButton]()
    
    var icon = Icon.success {
        didSet {
            iconView.image = icon.image
            animateIconIfNeeded()
        }
    }

    func set(title: String) {
        titleLabel.text = title
    }
    
    func set(message: String) {
        messageLabel.text = message
    }
    
    func set(buttons: [UIButton]) {
        buttons.forEach { button in
            button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            button.setContentHuggingPriority(.defaultLow, for: .horizontal)
            buttonStack.addArrangedSubview(button)
            // 0.304 multiplier is 40% of 0.76 x screen width
            button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.304).isActive = true
        }
        self.buttons = buttons
    }

    func animateIconIfNeeded() {
        let animationKey = "rotationAnimation"
        if icon == .verifying {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.toValue = NSNumber(value: .pi * 2.0)
            rotationAnimation.duration = 1.2
            rotationAnimation.isCumulative = true
            rotationAnimation.repeatCount = .infinity
            iconView.layer.add(rotationAnimation, forKey: animationKey)
        } else {
            iconView.layer.removeAllAnimations()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIconIfNeeded()
    }

    static func create(title: String, message: String, icon: Icon) -> AlertViewController {
        let storyboard = UIStoryboard(name: "Alert", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "alert") as! AlertViewController
        vc.view.backgroundColor = .clear
        vc.modalPresentationStyle = .custom
        
        vc.set(title: title)
        vc.set(message: message)
        vc.icon = icon
        
        // TODO: animate loading image
        return vc
    }
    
}