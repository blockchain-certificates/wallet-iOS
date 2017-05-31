//
//  OnboardingViewController.swift
//  wallet
//
//  Created by Chris Downie on 5/30/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit

class LandingScreenViewController : UIViewController {
    override func viewDidLoad() {
//        navigationController?.setNavigationBarHidden(true, animated: false)
        title = ""
        
        // Remove the drop shadow
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        navigationController?.setNavigationBarHidden(true, animated: true)
    }
}

class RestoreAccountViewController: UIViewController {
    @IBOutlet weak var passphraseTextField: UITextField!
    
    override func viewDidLoad() {
        title = ""
    }
    override func viewWillAppear(_ animated: Bool) {
//        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func doneTapped() {
        savePassphrase()
    }
    
    func savePassphrase() {
        guard let passphrase = passphraseTextField.text else {
            return
        }
        
        guard Keychain.isValidPassphrase(passphrase) else {
            failedPassphrase(error: NSLocalizedString("This isn't a valid passphrase. Check what you entered and try again.", comment: "Invalid replacement passphrase error"))
            return
        }
        do {
            try Keychain.updateShared(with: passphrase)
            dismiss(animated: true, completion: nil)
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
extension RestoreAccountViewController : UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        savePassphrase()
    }
}

class PrenupViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @IBAction func doneTapped() {
        dismiss(animated: true, completion: nil)
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
        titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
        
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
        self.font = UIFont.systemFont(ofSize: 20, weight: UIFontWeightMedium)
    }
}
