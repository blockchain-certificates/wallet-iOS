//
//  OnboardingViewController.swift
//  wallet
//
//  Created by Chris Downie on 5/30/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit

class OnboardingControllerBase : UIViewController {
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var containerView : UIView!

    var defaultScrollViewInset : UIEdgeInsets {
        let padding: CGFloat
        if #available(iOS 11.0, *) {
            padding = (scrollView.frame.height - scrollView.contentLayoutGuide.layoutFrame.height) / 2
        } else {
            let safeHeight = scrollView.bounds.height
            padding = (safeHeight - containerView.bounds.height) / 2
        }
        
        return UIEdgeInsets(top: padding, left: 0, bottom: 0, right: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.layoutIfNeeded()
        scrollView.contentInset = defaultScrollViewInset
        scrollView.isScrollEnabled = scrollView.contentInset.top == 0
    }

}

class LandingScreenViewController : UIViewController {
    override func viewDidLoad() {
        title = ""
        view.backgroundColor = Style.Color.C3
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

class WelcomeReturningUsersViewController : UIViewController {
    override func viewDidLoad() {
        title = "Welcome"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

class NewUserViewController : OnboardingControllerBase {
    @IBOutlet weak var passphraseLabel : UILabel!

    var attempts = 5
    
    override func viewDidLoad() {
        title = NSLocalizedString("New User", comment: "Onboarding screen label for New User")
        generatePassphrase()
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
                // TODO: Should message user instead of crash? Is this plausible?
            } else {
                generatePassphrase()
            }
        }
    }
    
}


class OnboardingBackupMethods : OnboardingControllerBase, UIActivityItemSource {
    @IBOutlet var manualButton : CheckmarkButton!
    @IBOutlet var copyButton : CheckmarkButton!
    @IBOutlet var continueButton : PrimaryButton!
    
    static var hasPerformedBackup : Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultsKey.hasPerformedBackup)
    }
    
    func set(hasPerformedBackup: Bool) {
        UserDefaults.standard.set(hasPerformedBackup, forKey: UserDefaultsKey.hasPerformedBackup)
    }

    var hasWrittenPasscode = false {
        didSet {
            if hasWrittenPasscode {
                set(hasPerformedBackup: true)
            }
        }
    }
    var hasCopiedPasscode = false {
        didSet {
            if hasCopiedPasscode {
                set(hasPerformedBackup: true)
            }
        }
    }
    var passphrase : String?
    
    @IBAction func backupManual() {
        let storyboard = UIStoryboard(name: "Onboarding", bundle: Bundle.main)
        present(storyboard.instantiateViewController(withIdentifier: "manualBackup"), animated: true, completion: nil)

        hasWrittenPasscode = true
    }
    
    @IBAction func backupCopy() {
        let alert = AlertViewController.create(title: NSLocalizedString("Are you sure?", comment: "Confirmation before copying for backup"),
                                               message: NSLocalizedString("Email is a low-security backup method. Do you want to continue?", comment: "Scare tactic to warn user about insecurity of email"),
                                               icon: .warning)

        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(NSLocalizedString("Okay", comment: "Button to confirm user action"), for: .normal)
        okayButton.onTouchUpInside { [weak self] in
            alert.dismiss(animated: false, completion: nil)
            self?.presentCopySheet()
        }

        let cancelButton = SecondaryButton(frame: .zero)
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: "Button to cancel user action"), for: .normal)
        cancelButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
        }

        alert.set(buttons: [okayButton, cancelButton])

        present(alert, animated: false, completion: nil)
    }
    
    func presentCopySheet() {
        guard let passphrase = Keychain.loadSeedPhrase() else {
            // TODO: present alert? how to help user in this case?
            return
        }
        
        self.passphrase = passphrase
        let activity = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        
        present(activity, animated: true) {
            // TODO: can detect if user cancels?
            self.hasCopiedPasscode = true
            self.updateStates()
        }
    }
    
    @IBAction func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func updateStates() {
        manualButton.checked = hasWrittenPasscode
        copyButton.checked = hasCopiedPasscode
        continueButton.isEnabled = hasWrittenPasscode || hasCopiedPasscode

        let title = continueButton.isEnabled ?
            NSLocalizedString("Done", comment: "Button copy") :
            NSLocalizedString("Select at Least One to Continue", comment: "Button copy")

        continueButton.setTitle(title, for: .normal)
        continueButton.setTitle(title, for: .highlighted)
        continueButton.setTitle(title, for: .disabled)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Backup Passphrase", comment: "Onboarding screen backup passphrase title")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStates()
    }
    
    // MARK: - Activity Item Source
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return passphrase!
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        return passphrase! as NSString
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivityType?) -> String {
        return NSLocalizedString("BlockCerts Backup", comment: "Email subject line when backing up passphrase")
    }

}


class OnboardingManualBackup : OnboardingControllerBase {
    @IBOutlet var passphraseLabel : UILabel!
    
    @IBAction func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passphraseLabel.text = Keychain.loadSeedPhrase()
    }
}



class OnboardingCurrentUser : OnboardingControllerBase, UITextViewDelegate {
    @IBOutlet weak var textView : UITextView!

    @IBAction func savePassphrase() {
        guard let passphrase = textView.text else {
            return
        }
        
        let lowercasePassphrase = passphrase.lowercased()
        
        guard Keychain.isValidPassphrase(lowercasePassphrase) else {
            presentErrorAlert()
            return
        }
        do {
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasReenteredPassphrase)
            try Keychain.updateShared(with: lowercasePassphrase)
            dismiss(animated: false, completion: nil)
        } catch {
            presentErrorAlert()
        }
    }
    
    func presentErrorAlert() {
        let alert = AlertViewController.create(title: NSLocalizedString("Passphrase invalid", comment: "Title in alert view after processing failed user input"),
                                               message: NSLocalizedString("Please check your passphrase and try again.", comment: "Message to user to check the passphrase"),
                                               icon: .failure)
        
        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(NSLocalizedString("Okay", comment: "Button to confirm user action"), for: .normal)
        okayButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
        }
        
        alert.set(buttons: [okayButton])
        present(alert, animated: false, completion: nil)
    }
        
    // MARK: - Text view and keyboard
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.resignFirstResponder()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let keyboardScreenEndFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
                return
        }
        
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame.cgRectValue, from: view.window)
        
        if notification.name == Notification.Name.UIKeyboardWillHide {
            scrollView.contentInset = defaultScrollViewInset
        } else {
            // TODO: check these for iOS 11/iPhone X
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
            scrollView.isScrollEnabled = true
        }
        
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }

    // MARK: - View lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(adjustForKeyboard),
                                               name: Notification.Name.UIKeyboardWillHide,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(adjustForKeyboard),
                                               name: Notification.Name.UIKeyboardWillChangeFrame,
                                               object: nil)
    }
    
}




class RestoreAccountViewController : UIViewController {
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var passphraseTextView: UITextView!
    
    override func viewDidLoad() {
        title = ""
        let sideInsets : CGFloat = 16
        let vertInsets : CGFloat = 32
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

class GeneratedPassphraseViewController: UIViewController {
    @IBOutlet weak var passphraseLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    var attempts = 5
    
    override func viewDidLoad() {
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
