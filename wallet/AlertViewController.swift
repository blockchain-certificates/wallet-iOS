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
    
    enum AlertType {
        case normal
        case progress
        case verification
    }
    
    // Normal Alert
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var buttonStack: UIStackView!
    
    // Progress Alert
    @IBOutlet weak var progressAlertView: UIView!
    @IBOutlet weak var progressIconView: UIImageView!
    @IBOutlet weak var progressTitleLabel: UILabel!
    
    // Certificate Verification Alert
    @IBOutlet weak var verificationAlertView: UIView!
    @IBOutlet weak var verificationIconView: UIImageView!
    @IBOutlet weak var verificationHeaderLabel: UILabel!
    @IBOutlet weak var verificationTitleLabel: UILabel!
    @IBOutlet weak var verificationMessageLabel: UILabel!
    @IBOutlet weak var verificationButtonStack: UIStackView!
    
    var icon = Icon.success {
        didSet {
            iconView.image = icon.image
            progressIconView.image = icon.image
            verificationIconView.image = icon.image
            animateIconIfNeeded()
        }
    }
    
    var type = AlertType.normal {
        didSet {
            alertView.isHidden = true
            progressAlertView.isHidden = true
            verificationAlertView.isHidden = true
            
            switch type {
            case .normal:
                alertView.isHidden = false
                
            case .progress:
                progressAlertView.isHidden = false
                
            case .verification:
                verificationAlertView.isHidden = false
            }
        }
    }
    
    var buttons = [UIButton]()
    var verificationButtons =  [UIButton]()
    
    func set(header: String) {
        verificationHeaderLabel.text = header
    }
    
    func set(title: String) {
        titleLabel.text = title
        progressTitleLabel.text = title
        verificationTitleLabel.text = title
    }
    
    func set(message: String) {
        messageLabel.text = message
        verificationMessageLabel.text = message
    }
    
    func set(buttons: [UIButton], clear: Bool = false) {
        if clear {
            buttonStack.arrangedSubviews.forEach {
                buttonStack.removeArrangedSubview($0)
            }
        }
        
        buttons.forEach { button in
            button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            button.setContentHuggingPriority(.defaultLow, for: .horizontal)
            buttonStack.addArrangedSubview(button)
            // 0.304 multiplier is 40% of 0.76 x screen width
            button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.304).isActive = true
            button.heightAnchor.constraint(equalToConstant: Style.Measure.heightButtonSmall).isActive = true
        }
        self.buttons = buttons
    }
    
    func set(verificationButtons: [UIButton], clear: Bool = false) {
        if clear {
            verificationButtonStack.arrangedSubviews.forEach {
                verificationButtonStack.removeArrangedSubview($0)
            }
        }
        
        verificationButtons.forEach { button in
            button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            button.setContentHuggingPriority(.defaultLow, for: .horizontal)
            verificationButtonStack.addArrangedSubview(button)
            // 0.304 multiplier is 40% of 0.76 x screen width
            button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.304).isActive = true
            button.heightAnchor.constraint(equalToConstant: Style.Measure.heightButtonSmall).isActive = true
        }
        self.verificationButtons = verificationButtons
    }

    func animateIconIfNeeded() {
        let animationKey = "rotationAnimation"
        if icon == .verifying {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.toValue = NSNumber(value: .pi * 2.0)
            rotationAnimation.duration = 1.2
            rotationAnimation.isCumulative = true
            rotationAnimation.repeatCount = .infinity
            
            switch type {
            case .normal:
                iconView.layer.add(rotationAnimation, forKey: animationKey)
                
            case .progress:
                progressIconView.layer.add(rotationAnimation, forKey: animationKey)
                
            case .verification:
                verificationIconView.layer.add(rotationAnimation, forKey: animationKey)
            }
        } else {
            iconView.layer.removeAllAnimations()
            progressIconView.layer.removeAllAnimations()
            verificationIconView.layer.removeAllAnimations()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIconIfNeeded()
    }

    static func create(title: String, message: String, icon: Icon, buttonText: String? = nil, buttonAction: (() -> Void)? = nil) -> AlertViewController {
        let vc = createFromStoryboard()
        vc.type = .normal
        vc.set(title: title)
        vc.set(message: message)
        vc.icon = icon

        if let buttonText = buttonText {
            // assume a simple, single button to dismiss the alert
            let button = SecondaryButton(frame: .zero)
            button.setTitle(buttonText, for: .normal)
            button.onTouchUpInside {
                buttonAction?()
                vc.dismiss(animated: false, completion: nil)
            }
            vc.set(buttons: [button])
       }
        
        return vc
    }
    
    static func createWarning(title: String, message: String, buttonText: String? = nil) -> AlertViewController {
        let vc = createFromStoryboard()
        vc.type = .normal
        vc.set(title: title)
        vc.set(message: message)
        vc.icon = .warning
        
        // assume a simple, single button to dismiss the alert
        let button = DangerButton(frame: .zero)
        let buttonCopy = buttonText ?? Localizations.Okay
        button.setTitle(buttonCopy, for: .normal)
        button.onTouchUpInside {
            vc.dismiss(animated: false, completion: nil)
        }
        vc.set(buttons: [button])
        
        return vc
    }
    
    static func createNetworkWarning() -> AlertViewController {
        return createWarning(title: Localizations.ReachabilityAlertTitle,
                             message: Localizations.ReachabilityAlertMessage)
    }
    
    static func createProgress(title: String) -> AlertViewController {
        let vc = createFromStoryboard()
        vc.type = .progress
        vc.set(title: title)
        vc.icon = .verifying
        
        return vc
    }
    
    static func createVerification(header: String, title: String, message: String) -> AlertViewController {
        let vc = createFromStoryboard()
        vc.type = .verification
        vc.set(header: header)
        vc.set(title: title)
        vc.set(message: message)
        vc.icon = .verifying
        
        return vc
    }
    
    static func createAppUpdate() -> AlertViewController {
        let vc = createWarning(title: Localizations.AppUpdateAlertTitle,
                               message: Localizations.AppUpdateAlertMessage)
        
        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside {
            let url = URL(string: "itms://itunes.apple.com/us/app/blockcerts-wallet/id1146921514")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            vc.dismiss(animated: false, completion: nil)
        }
        
        let cancelButton = SecondaryButton(frame: .zero)
        cancelButton.setTitle(Localizations.Cancel, for: .normal)
        cancelButton.onTouchUpInside {
            vc.dismiss(animated: false, completion: nil)
        }
        
        vc.set(buttons: [okayButton, cancelButton])
        return vc
    }
    
    static func createFromStoryboard() -> AlertViewController {
        let storyboard = UIStoryboard(name: "Alert", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "alert") as! AlertViewController
        vc.view.backgroundColor = .clear
        vc.modalPresentationStyle = .custom
        return vc
    }
}
