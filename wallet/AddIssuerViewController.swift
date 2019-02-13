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
    
    //logger tag
    private let tag = String(describing: AddIssuerViewController.self)

    private var inProgressRequest: CommonRequest?
    var delegate: AddIssuerViewControllerDelegate?
    var managedIssuer: ManagedIssuer?
    var progressAlert: AlertViewController?
    var presentedModally = false
    
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var issuerURLContainer: UIView!
    @IBOutlet weak var issuerURLLabel: UILabel!
    @IBOutlet weak var issuerURLField: UITextView!
    @IBOutlet weak var nonceContainer: UIView!
    @IBOutlet weak var nonceLabel: UILabel!
    @IBOutlet weak var nonceField : UITextView!
    @IBOutlet weak var submitButton : UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Logger.main.tag(tag).info("view_did_load")
        
        title = Localizations.AddIssuer
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
        
        issuerURLContainer.isAccessibilityElement = true
        issuerURLContainer.accessibilityTraits = issuerURLField.accessibilityTraits
        issuerURLContainer.accessibilityHint = issuerURLLabel.text
        issuerURLLabel.isAccessibilityElement = false
        issuerURLField.isAccessibilityElement = false
        
        nonceContainer.isAccessibilityElement = true
        nonceContainer.accessibilityTraits = nonceField
            .accessibilityTraits
        nonceContainer.accessibilityHint = nonceLabel.text
        nonceLabel.isAccessibilityElement = false
        nonceField.isAccessibilityElement = false
    }

    @IBAction func addIssuerTapped(_ sender: Any) {
        Logger.main.tag(tag).info("add_issuer tapped")
        identifyAndIntroduceIssuer()
    }

    @objc func cancelTapped(_ sender: UIBarButtonItem) {
        Logger.main.tag(tag).info("cancel_add_issuer tapped")
        dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardDidShow(notification: NSNotification) {
        Logger.main.tag(tag).info("keyboard show")
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
        Logger.main.tag(tag).info("keyboard hide")
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    func identifyAndIntroduceIssuer() {
        Logger.main.tag(tag).info("identify_and_introduce_user")
        guard let urlString = issuerURLField.text, let url = URL(string: urlString), let nonce = nonceField.text else {
            Logger.main.tag(tag).error("url and one_time_code fields validation failed")
            return
        }
        
        Logger.main.tag(tag).debug("identify_and_introduce_user url: \(urlString) one_time_code: \(nonce)")
        
        Logger.main.tag(tag).info("checking network")
        if !Reachability.isNetworkReachable() {
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            Logger.main.tag(tag).error("network unreachable")
            return
        }
        Logger.main.tag(tag).info("network reachable")
        
        progressAlert = AlertViewController.createProgress(title: Localizations.AddingIssuer)
        present(progressAlert!, animated: false, completion: nil)
        
        Logger.main.tag(tag).info("checking update required")
        AppVersion.checkUpdateRequired { [weak self] updateRequired in
            guard !updateRequired else {
                Logger.main.tag(self?.tag).warning("app update needed")
                self?.showAppUpdateError()
                return
            }
            Logger.main.tag(self?.tag).info("no update required")
            
            self?.cancelWebLogin()
        
            Logger.main.tag(self?.tag).info("creating managed_issuer")
            self?.managedIssuer = ManagedIssuer()
            self?.managedIssuer!.delegate = self
            self?.managedIssuer!.add(from: url, nonce: nonce, completion: { error in
                guard error == nil else {
                    Logger.main.tag(self?.tag).error("managed_issuer.add completion with error")
                    self?.showAddIssuerError()
                    return
                }
                
                if let managedIssuer = self?.managedIssuer {
                    self?.delegate?.added(managedIssuer: managedIssuer)
                }
                
                Logger.main.tag(self?.tag).info("managed_issuer.add completion with success")
                self?.dismissWebView()
                self?.showAddIssuerSuccess()
            })
        }
    }
    
    func showAddIssuerSuccess() {
        Logger.main.tag(tag).info("show add_issuer_success")
        guard let progressAlert = self.progressAlert else { return }
        
        progressAlert.type = .normal
        progressAlert.set(title: Localizations.Success)
        progressAlert.set(message: Localizations.AddIssuerSuccess)
        progressAlert.icon = .success
        
        let okayButton = DialogButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside { [weak self] in
            progressAlert.dismiss(animated: false, completion: nil)
            
            if self?.presentedModally ?? true {
                self?.presentingViewController?.dismiss(animated: true, completion: nil)
            } else {
                self?.navigationController?.popViewController(animated: true)
            }
            
            Logger.main.tag(self?.tag).info("dismiss add_issuer_success")
        }
        progressAlert.set(buttons: [okayButton])
        
        if self.presentedViewController != progressAlert {
            Logger.main.tag(tag).info("presenting add_issuer_success")
            self.present(progressAlert, animated: false, completion: nil)
        }
    }
    
    func showAppUpdateError() {
        let tag = self.tag
        Logger.main.tag(tag).info("show app_update_error")
        guard let progressAlert = progressAlert else { return }
        
        progressAlert.type = .normal
        progressAlert.set(title: Localizations.AppUpdateAlertTitle)
        progressAlert.set(message: Localizations.AppUpdateAlertMessage)
        progressAlert.icon = .warning
        
        let okayButton = DialogButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside {
            let url = URL(string: "itms://itunes.apple.com/us/app/blockcerts-wallet/id1146921514")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            progressAlert.dismiss(animated: false, completion: nil)
            
            Logger.main.tag(tag).debug("tapped update_app with link: \(url)")
        }
        
        let cancelButton = DialogButton(frame: .zero)
        cancelButton.setTitle(Localizations.Cancel, for: .normal)
        cancelButton.onTouchUpInside {
            progressAlert.dismiss(animated: false, completion: nil)
            
            Logger.main.tag(tag).warning("tapped update_dismiss")
        }
        
        progressAlert.set(buttons: [cancelButton, okayButton])
    }
    
    func showAddIssuerError() {
        let tag = self.tag

        Logger.main.tag(tag).info("show add_issuer_error")
        guard let progressAlert = progressAlert else { return }
        
        progressAlert.type = .normal
        progressAlert.set(title: Localizations.AddIssuerFailAlertTitle)
        progressAlert.set(message: Localizations.AddIssuerFailMessage)
        progressAlert.icon = .failure
        
        let okayButton = DialogButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside {
            Logger.main.tag(tag).info("dismiss add_issuer_error")
            progressAlert.dismiss(animated: false, completion: nil)
        }
        progressAlert.set(buttons: [okayButton])
    }
    
    // MARK: - ManagedIssuerDelegate
    
    var webViewNavigationController: NavigationController?
    
    func presentWebView(at url: URL, with navigationDelegate: WKNavigationDelegate) throws {
        Logger.main.tag(tag).debug("present web view with url: \(url)")
        
        let webController = WebLoginViewController(requesting: url, navigationDelegate: navigationDelegate) { [weak self] in
            self?.cancelWebLogin()
            self?.dismissWebView()
        }
        let navigationController = NavigationController(rootViewController: webController)
        webViewNavigationController = navigationController
        
        DispatchQueue.main.async {
            self.progressAlert?.dismiss(animated: false, completion: {
                self.present(navigationController, animated: true, completion: nil)
            })
        }
    }
    
    func dismissWebView() {
        Logger.main.tag(tag).debug("dismiss web_view")
        DispatchQueue.main.async { [weak self] in
            self?.webViewNavigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func cancelWebLogin() {
        Logger.main.tag(tag).debug("cancel web_login")
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
