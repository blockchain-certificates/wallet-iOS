//
//  AccountViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/13/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import CommonCrypto

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

        // Do any additional setup after loading the view.
//        navigationBar.barTintColor = Colors.translucentBrandColor
//        navigationBar.tintColor = Colors.tintColor
//        navigationBar.titleTextAttributes = [
//            NSForegroundColorAttributeName: Colors.tintColor
//        ]
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

    @IBAction func emailChanged(_ sender: UITextField) {
        guard let email = sender.text else {
            // TODO: Validate that it's actually an email address
            return
        }
        guard let hash = md5(email),
            let gravatarURL = URL(string: "https://www.gravatar.com/avatar/\(hash)?s=100") else {
            return
        }
        
        UserDefaults.standard.set(gravatarURL, forKey: UserKeys.avatarURLKey)
        
        loadAvatarImage(from: gravatarURL)
    }
    
    @IBAction func toggleShowPassphraseTapped(_ sender: UIButton) {
        isShowingPassphrase = !isShowingPassphrase
        if isShowingPassphrase {
            self.toggleShowPassphraseButton.setTitle("Hide passphrase", for: .normal)
            self.passphraseLabel.text = Keychain.shared.seedPhrase
        } else {
            self.toggleShowPassphraseButton.setTitle("Reveal passphrase", for: .normal)
            self.passphraseLabel.text = passphraseExplanation
        }
    }
    
    @IBAction func importPassphraseTapped(_ sender: UIButton) {
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
        
        if let avatarURL = UserDefaults.standard.url(forKey: UserKeys.avatarURLKey) {
            loadAvatarImage(from: avatarURL)
        }

    }
    
    func saveAccount() {
        UserDefaults.standard.set(firstNameField.text, forKey: UserKeys.firstNameKey)
        UserDefaults.standard.set(lastNameField.text, forKey: UserKeys.lastNameKey)
        UserDefaults.standard.set(emailField.text, forKey: UserKeys.emailKey)
    }
    
    func loadAvatarImage(from url: URL) {
        OperationQueue.main.addOperation { [weak self] in
            self?.imageLoadingActivityIndicator.isHidden = false
            self?.imageLoadingActivityIndicator.startAnimating()
            
            let task : URLSessionDataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, _, _) in
                OperationQueue.main.addOperation {
                    if let data = data {
                        self?.avatarImageView.image = UIImage(data: data)
                    }
                    
                    self?.imageLoadingActivityIndicator.stopAnimating()
                    self?.imageLoadingActivityIndicator.isHidden = true
                }
                self?.task = nil
            }
            task.resume()
            self?.task?.cancel()
            self?.task = task
        }
    }
    
    private func md5(_ string: String) -> String? {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        
        
        if let data = string.data(using: .utf8) {
            _ = data.withUnsafeBytes {
                CC_MD5($0, CC_LONG(length), &digest)
            }
        }
        
        var digestHex = ""
        for index in 0..<length {
            digestHex += String(format: "%02x", digest[index])
        }
        
        return digestHex
    }
}
