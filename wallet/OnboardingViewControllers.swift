//
//  OnboardingViewController.swift
//  wallet
//
//  Created by Chris Downie on 5/30/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import AVKit

class OnboardingControllerBase : UIViewController {
    
    @IBAction func playWelcomeVideo() {
        guard let path = Bundle.main.path(forResource: "introduction", ofType:"mp4") else {
            print("Video file not found")
            return
        }
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        let playerController = AVPlayerViewController()
        playerController.player = player
        playerController.showsPlaybackControls = true
        if #available(iOS 11.0, *) {
            playerController.exitsFullScreenWhenPlaybackEnds = true
        } else {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(didEndPlaying),
                                                   name: .AVPlayerItemDidPlayToEndTime,
                                                   object: nil)
        }
        present(playerController, animated: true) {
            player.play()
        }
    }
    
    @objc func didEndPlaying(_ notification: Notification) {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
}

class ScrollingOnboardingControllerBase : OnboardingControllerBase {
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
        
        return UIEdgeInsets(top: max(0, padding), left: 0, bottom: 0, right: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.layoutIfNeeded()
        scrollView.contentInset = defaultScrollViewInset
        scrollView.isScrollEnabled = scrollView.contentInset.top == 0
    }
    
}

class LandingScreenViewController : OnboardingControllerBase {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        view.backgroundColor = Style.Color.C3
    }
}

class WelcomeReturningUsersViewController : ScrollingOnboardingControllerBase {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Style.Color.C1
        title = NSLocalizedString("Welcome", comment: "Onboarding screen title")
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasReenteredPassphrase)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentInset = .zero
    }
}

class NewUserViewController : ScrollingOnboardingControllerBase {
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


class OnboardingBackupMethods : ScrollingOnboardingControllerBase, UIActivityItemSource {
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
        UIApplication.shared.statusBarStyle = .lightContent
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


class OnboardingManualBackup : ScrollingOnboardingControllerBase {
    @IBOutlet var passphraseLabel : UILabel!
    
    @IBAction func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passphraseLabel.text = Keychain.loadSeedPhrase()
        UIApplication.shared.statusBarStyle = .default
    }
}



class OnboardingCurrentUser : ScrollingOnboardingControllerBase, UITextViewDelegate {
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
