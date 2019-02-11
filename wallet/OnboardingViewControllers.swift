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

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
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
        navigationController?.styleHidden()
        
        let animation = LOTAnimationView(name: "welcome_lottie.json")
        animation.loopAnimation = true
        animation.contentMode = .scaleAspectFill
        animation.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(animation, at: 0)
        animation.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        animation.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        animation.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        animation.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        animation.play()
    }
}

class WelcomeReturningUsersViewController : ScrollingOnboardingControllerBase {
    
    @IBOutlet weak var videoPlayButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Style.Color.C1
        title = Localizations.Welcome
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasReenteredPassphrase)
        videoPlayButton.accessibilityLabel = Localizations.PlayIntroVideo
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
        super.viewDidLoad()
        title = Localizations.NewUser
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
        let alert = AlertViewController.create(title: Localizations.AreYouSure, message: Localizations.EmailBackupWarning, icon: .warning)

        let okayButton = DialogButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside { [weak self] in
            alert.dismiss(animated: false, completion: nil)
            self?.presentCopySheet()
        }

        let cancelButton = PrimaryButton(frame: .zero)
        cancelButton.titleLabel?.font = Style.Font.T2S
        cancelButton.setTitle(Localizations.Cancel, for: .normal)
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

        let title = continueButton.isEnabled ? Localizations.Done : Localizations.SelectOneButton
        continueButton.setTitle(title, for: .normal)
        continueButton.setTitle(title, for: .highlighted)
        continueButton.setTitle(title, for: .disabled)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localizations.BackupPassphrase
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
        return Localizations.BlockcertsBackup
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
        passphraseLabel.font = Style.Font.T3S
        passphraseLabel.textColor = Style.Color.C3

        UIApplication.shared.statusBarStyle = .default
    }
}

class OnboardingCurrentUser : ScrollingOnboardingControllerBase, UITextViewDelegate {
    @IBOutlet weak var textView : UITextView!
    @IBOutlet weak var submitButton : UIButton!

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
        let alert = AlertViewController.create(title: Localizations.InvalidPassphrase,
                                               message: Localizations.CheckPassphraseTryAgain,
                                               icon: .failure)
        
        let okayButton = DialogButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
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
    
    func textViewDidChange(_ textView: UITextView) {
        submitButton.isEnabled = textView.text.count > 0
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
        textView.font = Style.Font.T3S
        textView.textColor = Style.Color.C3
        submitButton.isEnabled = false
        
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
