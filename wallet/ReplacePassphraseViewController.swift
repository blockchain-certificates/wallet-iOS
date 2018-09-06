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
        
        title = Localizations.ReplacePassphrase
        errorLabel.text = nil

        let horizontalSpace : CGFloat = 15
        passphraseField.textContainerInset = UIEdgeInsets(top: 4, left: horizontalSpace, bottom: 20, right: horizontalSpace)
        
        // Do any additional setup after loading the view.
        replaceButton = UIBarButtonItem(title: Localizations.Replace,
                                        style: .done,
                                        target: self,
                                        action: #selector(saveNewPassphrase))
        
        navigationItem.rightBarButtonItem = replaceButton
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    @objc func saveNewPassphrase() {
        resignFirstResponder()
        errorLabel.text = nil
        
        guard let requestedPassphrase = passphraseField.text else {
            return
        }
        
        guard Keychain.isValidPassphrase(requestedPassphrase) else {
            failedToSave(Localizations.InvalidPassphrase)
            return
        }
        
        authenticateUser { (success, error) in
            guard success else {
                self.failedToSave(Localizations.AuthenticationError)
                return
            }
            do {
                try Keychain.updateShared(with: requestedPassphrase)
                self.successfulSave()
            } catch {
                self.failedToSave(Localizations.AuthenticationError)
            }
        }
    }
    
    func successfulSave() {
        DispatchQueue.main.async {
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
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: Localizations.AuthenticateReplacePassphrase, reply: completionHandler)
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: Localizations.AuthenticateReplacePassphrase,
                reply: completionHandler)
        } else {
            completionHandler(false, AuthErrors.noAuthMethodAllowed)
        }
    }
}
