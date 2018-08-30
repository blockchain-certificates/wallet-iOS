//
//  MyPassphraseViewController.swift
//  certificates
//
//  Created by Michael Shin on 8/30/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import UIKit

class MyPassphraseViewController : ScrollingOnboardingControllerBase, UIActivityItemSource {
    @IBOutlet var manualButton : SecondaryButton!
    @IBOutlet var copyButton : SecondaryButton!
    @IBOutlet var passphraseLabel : UILabel!
    
    var passphrase: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        passphraseLabel.text = Keychain.loadSeedPhrase()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.instance.styleApplicationDefault()
    }
    
    override var defaultScrollViewInset : UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    @IBAction func backupCopy() {
        let alert = AlertViewController.create(title: NSLocalizedString("Are you sure?", comment: "Confirmation before copying for backup"),
                                               message: NSLocalizedString("This is a low-security backup method. Do you want to continue?", comment: "Scare tactic to warn user about insecurity of email"),
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
        
        AppDelegate.instance.styleApplicationAlternate()
        
        present(activity, animated: true) {}
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
        return NSLocalizedString("Blockcerts Backup", comment: "Email subject line when backing up passphrase")
    }
    
}
