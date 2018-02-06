//
//  OnboardingViewController.swift
//  wallet
//
//  Created by Chris Downie on 5/30/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit

class LandingScreenViewController : UIViewController {
    @IBOutlet weak var logoImageView: UIImageView!
    override func viewDidLoad() {
        title = ""
        view.backgroundColor = Style.Color.primary
        
        // Remove the drop shadow
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = .default
    }
}

class RestoreAccountViewController: UIViewController {
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var passphraseTextView: UITextView!
    
    override func viewDidLoad() {
        title = ""
        let sideInsets : CGFloat = 16
        let vertInsets : CGFloat = 32
        logoImageView.tintColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0)
        passphraseTextView.textContainerInset = UIEdgeInsets(top: vertInsets, left: sideInsets, bottom: vertInsets, right: sideInsets)
        passphraseTextView.delegate = self
    }
    
    @IBAction func doneTapped() {
        savePassphrase()
    }
    
    func savePassphrase() {
        guard let passphrase = passphraseTextView.text else {
            return
        }
        
        guard Keychain.isValidPassphrase(passphrase) else {
            failedPassphrase(error: NSLocalizedString("This isn't a valid passphrase. Check what you entered and try again.", comment: "Invalid replacement passphrase error"))
            return
        }
        do {
            try Keychain.updateShared(with: passphrase)
            dismiss(animated: true, completion: {
                NotificationCenter.default.post(name: NotificationNames.onboardingComplete, object: nil)
            })
        } catch {
            failedPassphrase(error: NSLocalizedString("This isn't a valid passphrase. Check what you entered and try again.", comment: "Invalid replacement passphrase error"))
        }
    }
    
    func failedPassphrase(error : String) {
        let title = NSLocalizedString("Invalid passphrase", comment: "Title when trying to use an invalid passphrase as your passphrase")
        let controller = UIAlertController(title: title, message: error, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "confirm action"), style: .cancel, handler: nil))
        present(controller, animated: true, completion: nil)
    }
}

extension RestoreAccountViewController : UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            savePassphrase()
            return false
        }
        return true
    }
}

class PrenupViewController: UIViewController {
    @IBOutlet weak var logoImageView: GreyTintImageView!
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        logoImageView.tintColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0)
    }
    override func viewDidLoad() {
        title = ""
    }
}

class GeneratedPassphraseViewController: UIViewController {
    @IBOutlet weak var passphraseLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    var attempts = 5
    
    override func viewDidLoad() {
        title = ""
        generatePassphrase()
        
        logoImageView.tintColor = UIColor(red:0.00, green:0.54, blue:0.48, alpha:1.0)
        passphraseLabel.accessibilityIdentifier = "GeneratedPassphrase"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @IBAction func doneTapped() {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: NotificationNames.onboardingComplete, object: nil)
        }
    }
    
    func generatePassphrase() {
        let passphrase = Keychain.generateSeedPhrase()

        do {
            try Keychain.updateShared(with: passphrase)
            passphraseLabel.text = passphrase
        } catch {
            attempts -= 1
            
            if attempts < 0 {
                fatalError("Couldn't generate a passphrase after failing 5 times.")
            } else {
                generatePassphrase()
            }
        }

    }
}


// MARK: - CUstom UI elements

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
    
    let textColor = Style.Color.white
    let strokeColor = Style.Color.secondary
    let fillColor = Style.Color.secondary
    
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

    let textColor = Style.Color.secondary
    let strokeColor = Style.Color.secondary
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
class RectangularButton : UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        let edgeInsets : CGFloat = 20
        
        backgroundColor = .white
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 0.5
        contentEdgeInsets = UIEdgeInsets(top: edgeInsets, left: edgeInsets, bottom: edgeInsets, right: edgeInsets)
        tintColor = .black
        titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        
        setTitleColor(.black, for: .normal)
        setTitleColor(.black, for: .selected)
        setTitleColor(.black, for: .highlighted)
        setTitleColor(.black, for: .focused)
        setTitleShadowColor(.red, for: .highlighted)
    }
}

@IBDesignable
class SecondaryRectangularButton : RectangularButton {
    override func commonInit() {
        super.commonInit()
        backgroundColor = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.0)
    }
}

@IBDesignable
class TitleLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        self.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
    }
}

@IBDesignable
class GreenTintImageView: UIImageView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateTint()
    }
    override init(image: UIImage?) {
        super.init(image: image)
        updateTint()
    }
    override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        updateTint()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        updateTint()
    }
    
    func updateTint() {
        tintColor = #colorLiteral(red: 0.1647058824, green: 0.6980392157, blue: 0.4823529412, alpha: 1)
    }
}

@IBDesignable
class GreyTintImageView: UIImageView {
    func updateTint() {
        tintColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    }
}
