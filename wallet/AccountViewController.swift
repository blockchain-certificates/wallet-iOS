//
//  AccountViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/13/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import CommonCrypto
import LocalAuthentication

class AccountViewController: UIViewController {

    var task : URLSessionDataTask?
    let passphraseExplanation = "Your accomplishments are secured by a secure passphrase. Be sure to write your passphrase down in a safe place, in case you lose your phone."
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var imageLoadingActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!

    @IBOutlet weak var passphraseLabel: UILabel!
    @IBOutlet weak var toggleShowPassphraseButton: UIButton!
    private var isShowingPassphrase = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadAccount()
        
        self.title = "Account"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped(_:)))
    }
    override func viewWillDisappear(_ animated: Bool) {
        // 
        saveAccount()
    }

    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toggleShowPassphraseTapped(_ sender: UIButton) {
        guard !isShowingPassphrase else {
            isShowingPassphrase = false
            self.toggleShowPassphraseButton.setTitle("Reveal passphrase", for: .normal)
            self.passphraseLabel.text = passphraseExplanation
            return
        }
        
        authenticateUser { (success, error) in
            guard success else {
                // TODO: Have some UI that indicates the failure.
                return
            }
            
            OperationQueue.main.addOperation {
                self.isShowingPassphrase = true
                self.toggleShowPassphraseButton.setTitle("Hide passphrase", for: .normal)
                self.passphraseLabel.text = Keychain.shared.seedPhrase
            }
        }
    }
    
    @IBAction func importPassphraseTapped(_ sender: UIButton) {
        let prompt = UIAlertController(title: nil, message: "What passphrase would you like to import?", preferredStyle: .alert)
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(UIAlertAction(title: "Import", style: .destructive, handler: { (action) in
            var errorMessage : String?
            
            let passphrase = prompt.textFields?.first?.text
            
            if passphrase == nil || passphrase!.isEmpty {
                errorMessage = "You can't use an empty passphrase"
            } else if !Keychain.isValidPassphrase(passphrase!) {
                errorMessage = "The passphrase you entered isn't valid. Double check that you've entered the passphrase correctly."
            }
            
            if let phrase = passphrase, errorMessage == nil {
                do {
                    try Keychain.updateShared(with: phrase)
                } catch {
                    errorMessage = "Failed to update your passphrase. Try again?"
                }
            }
            
            if let message = errorMessage {
                OperationQueue.main.addOperation {
                    self.isShowingPassphrase = false
                    self.passphraseLabel.text = message
                    self.toggleShowPassphraseButton.setTitle("Reveal passphrase", for: .normal)
                }
            } else {
                OperationQueue.main.addOperation {
                    self.isShowingPassphrase = false
                    self.passphraseLabel.text = "Your passphrase has been updated."
                    self.toggleShowPassphraseButton.setTitle("Reveal passphrase", for: .normal)
                }
            }
        }))
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(prompt, animated: true, completion: nil)
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
            // TODO: Use a real error here.
            completionHandler(false, NSError())
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func loadAccount() {
        let firstName = UserDefaults.standard.string(forKey: UserKeys.firstNameKey)
        let lastName = UserDefaults.standard.string(forKey: UserKeys.lastNameKey)
        let email = UserDefaults.standard.string(forKey: UserKeys.emailKey)
        
        firstNameField.text = firstName
        lastNameField.text = lastName
        emailField.text = email
    }
    
    func saveAccount() {
        UserDefaults.standard.set(firstNameField.text, forKey: UserKeys.firstNameKey)
        UserDefaults.standard.set(lastNameField.text, forKey: UserKeys.lastNameKey)
        UserDefaults.standard.set(emailField.text, forKey: UserKeys.emailKey)
    }
}
