//
//  AddIssuerViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/13/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import WebKit
import Blockcerts

class AddIssuerViewController: UIViewController, ManagedIssuerDelegate {
    
    private var inProgressRequest: CommonRequest?
    var delegate: AddIssuerViewControllerDelegate?
    var managedIssuer: ManagedIssuer?
    var progressAlert: AlertViewController?
    var presentedModally = false
    
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var issuerURLField: UITextView!
    @IBOutlet weak var nonceField : UITextView!
    @IBOutlet weak var submitButton : UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Add an Issuer", comment: "Navigation title for the 'Add Issuer' form.")
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = Style.Color.C3
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        issuerURLField.delegate = self
        issuerURLField.font = Style.Font.T3S
        issuerURLField.textColor = Style.Color.C3

        nonceField.delegate = self
        nonceField.font = Style.Font.T3S
        nonceField.textColor = Style.Color.C3
        
        submitButton.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }

    @IBAction func addIssuerTapped(_ sender: Any) {
        Logger.main.info("Save issuer tapped")
        identifyAndIntroduceIssuer()
    }

    @objc func cancelTapped(_ sender: UIBarButtonItem) {
        Logger.main.info("Cancel Add Issuer tapped")
        dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardDidShow(notification: NSNotification) {
        guard let info = notification.userInfo,
            let keyboardRect = info[UIKeyboardFrameBeginUserInfoKey] as? CGRect else {
            return
        }

        let scrollInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardRect.size.height, right: 0)
        scrollView.isScrollEnabled = true
        scrollView.contentInset = scrollInsets
        scrollView.scrollIndicatorInsets = scrollInsets
    }
    
    @objc func keyboardDidHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    func identifyAndIntroduceIssuer() {
        guard let urlString = issuerURLField.text, let url = URL(string: urlString), let nonce = nonceField.text else {
            return
        }
        
        if !Reachability.isNetworkReachable() {
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            return
        }
        
        progressAlert = AlertViewController.createProgress(title: NSLocalizedString("Adding Issuer", comment: "Title when adding issuer in progress"))
        present(progressAlert!, animated: false, completion: nil)
        
        AppVersion.checkUpdateRequired { [weak self] updateRequired in
            guard !updateRequired else {
                self?.showAppUpdateError()
                return
            }
            
            self?.cancelWebLogin()
            
            self?.managedIssuer = ManagedIssuer()
            self?.managedIssuer!.delegate = self
            self?.managedIssuer!.identify(from: url) { [weak self] identifyError in
                guard identifyError == nil else {
                    self?.showAddIssuerError()
                    return
                }
                
                self?.managedIssuer?.introduce(nonce: nonce) { introductionError in
                    guard introductionError == nil else {
                        self?.showAddIssuerError()
                        return
                    }
                    
                    self?.dismissWebView()
                    self?.notifyAndDismiss()
                }
            }
        }
    }
    
    func notifyAndDismiss() {
        if let managedIssuer = managedIssuer {
            delegate?.added(managedIssuer: managedIssuer)
        }
        
        DispatchQueue.main.async { [weak self] in
            
            guard let progressAlert = self?.progressAlert else {
                return
            }
            
            let title = NSLocalizedString("Success!", comment: "Add issuers alert title")
            let message = NSLocalizedString("An issuer was added. Please check your issuers screen.", comment: "Add issuer alert message")
            
            progressAlert.type = .normal
            progressAlert.set(title: title)
            progressAlert.set(message: message)
            progressAlert.icon = .success
            
            let okayButton = SecondaryButton(frame: .zero)
            okayButton.setTitle(NSLocalizedString("Okay", comment: "OK dismiss action"), for: .normal)
            okayButton.onTouchUpInside { [weak self] in
                progressAlert.dismiss(animated: false, completion: nil)
                
                if self?.presentedModally ?? true {
                    self?.presentingViewController?.dismiss(animated: true, completion: nil)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
            progressAlert.set(buttons: [okayButton])
            
            if self?.presentedViewController != progressAlert {
                self?.present(progressAlert, animated: false, completion: nil)
            }
        }
    }
    
    func showAppUpdateError() {
        Logger.main.info("App needs update.")
        guard let progressAlert = progressAlert else { return }
        
        progressAlert.type = .normal
        progressAlert.set(title: NSLocalizedString("[Old Version]", comment: "Force app update dialog title"))
        progressAlert.set(message: NSLocalizedString("[Lorem ipsum latin for go to App Store]", comment: "Force app update dialog message"))
        progressAlert.icon = .warning
        
        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(NSLocalizedString("Okay", comment: "Button copy"), for: .normal)
        okayButton.onTouchUpInside {
            let url = URL(string: "itms://itunes.apple.com/us/app/blockcerts-wallet/id1146921514")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            progressAlert.dismiss(animated: false, completion: nil)
        }
        
        let cancelButton = SecondaryButton(frame: .zero)
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: "Dismiss action"), for: .normal)
        cancelButton.onTouchUpInside {
            progressAlert.dismiss(animated: false, completion: nil)
        }
        
        progressAlert.set(buttons: [okayButton, cancelButton])
    }
    
    func showAddIssuerError() {
        guard let progressAlert = progressAlert else { return }
        
        DispatchQueue.main.async {
            
            let title = NSLocalizedString("Add Issuer Failed", comment: "Alert title when adding an issuer fails for any reason.")
            let cannedMessage = NSLocalizedString("There was an error adding this issuer. This can happen when a single-use invitation link is clicked more than once. Please check with the issuer and request a new invitation, if necessary.", comment: "Error message displayed when adding issuer failed")

            progressAlert.type = .normal
            progressAlert.set(title: title)
            progressAlert.set(message: cannedMessage)
            progressAlert.icon = .failure
            
            let okayButton = SecondaryButton(frame: .zero)
            okayButton.setTitle(NSLocalizedString("Okay", comment: "OK dismiss action"), for: .normal)
            okayButton.onTouchUpInside {
                progressAlert.dismiss(animated: false, completion: nil)
            }
            progressAlert.set(buttons: [okayButton])
        }
    }
    
    // MARK: - ManagedIssuerDelegate
    
    var webViewNavigationController: UINavigationController?
    
    func presentWebView(at url: URL, with navigationDelegate: WKNavigationDelegate) throws {
        Logger.main.info("Presenting the web view in the Add Issuer screen.")
        
        let webController = WebLoginViewController(requesting: url, navigationDelegate: navigationDelegate) { [weak self] in
            self?.cancelWebLogin()
            self?.dismissWebView()
        }
        let navigationController = UINavigationController(rootViewController: webController)
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.backgroundColor = Style.Color.C3
        navigationController.navigationBar.barTintColor = Style.Color.C3
        webViewNavigationController = navigationController
        
        OperationQueue.main.addOperation {
            self.progressAlert?.dismiss(animated: false, completion: {
                self.present(navigationController, animated: true, completion: nil)
            })
        }
    }
    
    func dismissWebView() {
        OperationQueue.main.addOperation { [weak self] in
            self?.webViewNavigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func cancelWebLogin() {
        managedIssuer?.abortRequests()
    }
}

struct ValidationOptions : OptionSet {
    let rawValue : Int
    
    static let required = ValidationOptions(rawValue: 1 << 0)
    static let url      = ValidationOptions(rawValue: 1 << 1)
    static let email    = ValidationOptions(rawValue: 1 << 2)
}

protocol AddIssuerViewControllerDelegate : class {
    func added(managedIssuer: ManagedIssuer)
}

extension AddIssuerViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if textView === issuerURLField {
                nonceField.becomeFirstResponder()
            } else {
                textView.resignFirstResponder()
            }
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        submitButton.isEnabled = nonceField.text.count > 0 && issuerURLField.text.count > 0
    }
}
