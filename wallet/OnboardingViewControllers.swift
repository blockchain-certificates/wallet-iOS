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
        navigationController?.setNavigationBarHidden(true, animated: false)
        title = ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
}

class RestoreAccountViewController: UIViewController {
    @IBOutlet weak var passphraseTextField: UITextField!
    
    override func viewDidLoad() {
        title = ""
    }
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
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
        backgroundColor = .white
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 0.5
        contentEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
    }
}
