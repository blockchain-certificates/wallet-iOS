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
        
        title = "Replace Passphrase"
        errorLabel.text = nil

        let horizontalSpace : CGFloat = 15
        passphraseField.tintColor = Colors.brandColor
        passphraseField.textContainerInset = UIEdgeInsets(top: 4, left: horizontalSpace, bottom: 20, right: horizontalSpace)
        
        // Do any additional setup after loading the view.
        view.backgroundColor = Colors.baseColor
        replaceButton = UIBarButtonItem(title: "Replace", style: .done, target: self, action: #selector(saveNewPassphrase))
        
        navigationItem.rightBarButtonItem = replaceButton
    }
    
    func saveNewPassphrase() {
        resignFirstResponder()
        errorLabel.text = nil
        
        guard let requestedPassphrase = passphraseField.text else {
            return
        }
        
        guard Keychain.isValidPassphrase(requestedPassphrase) else {
            failedToSave("This isn't a valid passphrase. Check what you entered & try again.")
            return
        }
        
        authenticateUser { (success, error) in
            guard success else {
                self.failedToSave("Failed to authenticate. Try again.")
                return
            }
            do {
                try Keychain.updateShared(with: requestedPassphrase)
                self.successfulSave()
            } catch {
                self.failedToSave("Unable to save this passphrase.")
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
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to see your secure passphrase.", reply: completionHandler)
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Authenticate to see your secure passphrase.",
                reply: completionHandler)
        } else {
            completionHandler(false, AuthErrors.noAuthMethodAllowed)
        }
    }
    
}
