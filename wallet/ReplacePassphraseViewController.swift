//
//  ReplacePassphraseViewController.swift
//  wallet
//
//  Created by Chris Downie on 1/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import LocalAuthentication

class ReplacePassphraseViewController: UIViewController {

    @IBOutlet weak var passphraseField: UITextView!
    @IBOutlet weak var passphraseLabel: UILabel!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    private var replaceButton : UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Replace Passphrase", comment: "Title for replacing the passphrase")
        errorLabel.text = nil

        let horizontalSpace : CGFloat = 15
        passphraseField.tintColor = Colors.brandColor
        passphraseField.textContainerInset = UIEdgeInsets(top: 4, left: horizontalSpace, bottom: 20, right: horizontalSpace)
        
        // Do any additional setup after loading the view.
        view.backgroundColor = Colors.baseColor
        replaceButton = UIBarButtonItem(title: NSLocalizedString("Replace", comment: "Replace passphrase action button"),
                                        style: .done,
                                        target: self,
                                        action: #selector(saveNewPassphrase))
        
        navigationItem.rightBarButtonItem = replaceButton
    }
    
    func saveNewPassphrase() {
        resignFirstResponder()
        errorLabel.text = nil
        
        guard let requestedPassphrase = passphraseField.text else {
            return
        }
        
        guard Keychain.isValidPassphrase(requestedPassphrase) else {
            failedToSave(NSLocalizedString("This isn't a valid passphrase. Check what you entered and try again.", comment: "Invalid replacement passphrase error"))
            return
        }
        
        authenticateUser { (success, error) in
            guard success else {
                self.failedToSave(NSLocalizedString("Failed to authenticate. Try again.", comment: "Auth failure replacing passphrase"))
                return
            }
            do {
                try Keychain.updateShared(with: requestedPassphrase)
                self.successfulSave()
            } catch {
                self.failedToSave(NSLocalizedString("Unable to save this passphrase.", comment: "Failure saving replacement passphrase"))
            }
        }
    }
    
    func successfulSave() {
        OperationQueue.main.addOperation {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    func failedToSave(_ reason: String) {
        errorLabel.text = reason
    }
    
    func authenticateUser(completionHandler: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error : NSError? = nil
        let reason = NSLocalizedString("Authenticate to replace your secure passphrase.", comment: "Explain that we need them to authenticate in order to replace their passphrase.")
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply: completionHandler)
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason,
                reply: completionHandler)
        } else {
            completionHandler(false, AuthErrors.noAuthMethodAllowed)
        }
    }
}
