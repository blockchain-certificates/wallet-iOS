//
//  AddCredentialViewController.swift
//  certificates
//
//  Created by Michael Shin on 8/30/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts

class AddCredentialViewController: UIViewController, UIDocumentPickerDelegate {
    private let tag = String(describing: AddCredentialViewController.self)
    
    var alert: AlertViewController?
    
    override func viewDidLoad() {
        Logger.main.tag(tag).info("view_did_load")
        super.viewDidLoad()
        navigationItem.title = Localizations.AddCredential
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Logger.main.tag(tag).info("view_will_appear")
        super.viewWillAppear(animated)
        navigationController?.styleDefault()
    }
    
    // MARK: - Add Credential
    
    @IBAction func importFromURL() {
        Logger.main.tag(tag).info("add credential from url")
        let storyboard = UIStoryboard(name: "Settings", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "addCredentialFromURL") as! AddCredentialURLViewController

        Logger.main.tag(tag).info("showing add credential url view controller")
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func importFromFile() {
        Logger.main.tag(tag).info("add credential from file")
        
        let controller = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
        controller.delegate = self
        controller.modalPresentationStyle = .formSheet

        Logger.main.tag(tag).info("showing document picker view controller")
        present(controller, animated: true) {
            self.navigationController?.styleDefault() // styleAlternate()
        }
    }
    
    func importCertificate(from data: Data?) {
        if let d = data {
            Logger.main.tag(tag).debug("importing certificate with data size: \(d)")
        } else {
            Logger.main.tag(tag).debug("importing certificate with data = nil")
        }

        Logger.main.tag(tag).info("checking network")
        if !Reachability.isNetworkReachable() {
            Logger.main.tag(tag).error("network unreachable")
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            return
        }
        Logger.main.tag(tag).info("network reachable")
        
        alert = AlertViewController.createProgress(title: Localizations.AddingCredential)
        present(alert!, animated: false, completion: nil)

        Logger.main.tag(tag).info("checking update required")
        AppVersion.checkUpdateRequired { [weak self] updateRequired in
            guard !updateRequired else {
                Logger.main.tag(self?.tag).error("update is required")
                self?.alertAppUpdate()
                return
            }
            Logger.main.tag(self?.tag).info("no update is required")
            
            guard let data = data else {
                Logger.main.tag(self?.tag).error("failed to load a certificate, data is nil")
                self?.alertError(title: Localizations.InvalidCredential, message: Localizations.InvalidCredentialFile)
                return
            }
            
            do {
                let certificate = try CertificateParser.parse(data: data)
                self?.saveCertificateIfOwned(certificate: certificate)
                
                self?.alertSuccess(callback: { [weak self] in
                    Logger.main.tag(self?.tag).info("success adding certificate")
                    self?.navigationController?.popViewController(animated: true)
                })
            } catch {
                Logger.main.tag(self?.tag).error("importing failed with error: \(error)")
                self?.alertError(title: Localizations.InvalidCredential, message: Localizations.InvalidCredentialFile)
                return
            }
        }
    }
    
    func saveCertificateIfOwned(certificate: Certificate) {
        guard !userCancelledAction else {
            Logger.main.tag(tag).info("user cancelled saving certificates")
            return
        }
        let manager = CertificateManager()
        Logger.main.tag(tag).info("calling save in CertificateManager")
        manager.save(certificate: certificate)
        NotificationCenter.default.post(name: NotificationNames.reloadCertificates, object: self, userInfo: nil)
    }
    
    var userCancelledAction = false
    
    // User tapped cancel in progress alert
    func cancelAddCredential() {
        Logger.main.tag(tag).info("user cancelled action")
        userCancelledAction = true
    }
    
    func alertError(title: String, message: String) {
        let tag = self.tag
        Logger.main.tag(tag).info("alerting error with title: \(title) and message: \(message)")
        guard let alert = alert else { return }
        
        alert.type = .normal
        alert.set(title: title)
        alert.set(message: message)
        alert.icon = .warning
        
        let okayButton = DialogButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside {
            Logger.main.tag(tag).info("tapped_ok dismiss")
            alert.dismiss(animated: false, completion: nil)
        }
        alert.set(buttons: [okayButton])
    }
    
    func alertSuccess(callback: (() -> Void)?) {
        let tag = self.tag
        Logger.main.tag(tag).info("alerting success")
        guard let alert = alert else { return }
        
        alert.type = .normal
        alert.set(title: Localizations.Success)
        alert.set(message: Localizations.CredentialImportSuccess)
        alert.icon = .success
        
        let okayButton = DialogButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: {
                Logger.main.tag(tag).info("tapped ok_dismiss")
                Logger.main.tag(tag).info("calling success callback")
                callback?()
            })
        }
        alert.set(buttons: [okayButton])
    }
    
    func alertAppUpdate() {
        let tag = self.tag
        Logger.main.tag(tag).info("show app_update_error")
        guard let alert = alert else { return }
        
        alert.type = .normal
        alert.set(title: Localizations.AppUpdateAlertTitle)
        alert.set(message: Localizations.AppUpdateAlertMessage)
        alert.icon = .warning
        
        let okayButton = DialogButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside {
            let url = URL(string: "itms://itunes.apple.com/us/app/blockcerts-wallet/id1146921514")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            alert.dismiss(animated: false, completion: nil)
            Logger.main.tag(tag).debug("tapped update_app with link: \(url)")
        }
        
        let cancelButton = DialogButton(frame: .zero)
        cancelButton.setTitle(Localizations.Cancel, for: .normal)
        cancelButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
            Logger.main.tag(tag).warning("tapped update_dismiss")
        }
        
        alert.set(buttons: [cancelButton, okayButton])
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let data = try? Data(contentsOf: url)
        Logger.main.tag(tag).info("document picker delegate, picked url: \(url)")
        importCertificate(from: data)
    }
    
}

class AddCredentialURLViewController: AddCredentialViewController, UITextViewDelegate {
    private let tag = String(describing: AddCredentialURLViewController.self)

    @IBOutlet weak var urlContainer: UIView!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var urlTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    
    // closure called when presented modally and credential successfully added
    var successCallback: ((Certificate) -> ())?
    var presentedModally = false
    
    @IBAction func importURL() {
        Logger.main.tag(tag).info("import_url")
        guard let urlString = urlTextView.text,
            let url = URL(string: urlString.trimmingCharacters(in: CharacterSet.whitespaces)) else {
            Logger.main.tag(tag).error("error getting url from text_view")
            return
        }

        Logger.main.tag(tag).error("checking network")
        if !Reachability.isNetworkReachable() {
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            Logger.main.tag(tag).error("network unreachable")
            return
        }
        Logger.main.tag(tag).info("network reachable")
        
        alert = AlertViewController.createProgress(title: Localizations.AddingCredential)
        present(alert!, animated: false, completion: nil)
        
        Logger.main.tag(tag).info("user attempting to add a certificate from \(url).")
        Logger.main.tag(tag).info("checking update required")
        AppVersion.checkUpdateRequired { [weak self] updateRequired in
            guard !updateRequired else {
                self?.alertAppUpdate()
                Logger.main.tag(self?.tag).error("app update required")
                return
            }

            Logger.main.tag(self?.tag).info("no update required")
            self?.addCertificate(from: url)
        }
    }
    
    func addCertificate(from url: URL) {
        Logger.main.tag(tag).info("add_certificate from url: \(url).")
        urlTextView.resignFirstResponder()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let certificate = CertificateManager().load(certificateAt: url) else {
                DispatchQueue.main.async { [weak self] in
                    Logger.main.tag(self?.tag).error("failed to load certificate from \(url)")
                    self?.alertError(title: Localizations.InvalidCredential, message: Localizations.InvalidCredentialFile)
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard !(self?.userCancelledAction ?? false) else {
                    Logger.main.tag(self?.tag).warning("user cancelled action")
                    return
                }
                Logger.main.tag(self?.tag).info("saving certificate")
                self?.saveCertificateIfOwned(certificate: certificate)

                Logger.main.tag(self?.tag).info("alerting success")
                self?.alertSuccess(callback: { [weak self] in
                    if self?.presentedModally ?? true {
                        self?.presentingViewController?.dismiss(animated: true, completion: { [weak self] in
                            self?.successCallback?(certificate)
                        })
                    } else {
                        self?.navigationController?.popViewController(animated: true)
                    }
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.main.tag(tag).info("view_did_load")

        urlTextView.backgroundColor = Style.Color.C10
        urlTextView.text = ""
        urlTextView.delegate = self
        urlTextView.font = Style.Font.T3S
        urlTextView.textColor = Style.Color.C3
        submitButton.isEnabled = false
        
        urlContainer.isAccessibilityElement = true
        urlContainer.accessibilityTraits = urlTextView
            .accessibilityTraits
        urlContainer.accessibilityHint = urlLabel.text
        urlLabel.isAccessibilityElement = false
        urlTextView.isAccessibilityElement = false
    }
    
    @objc func dismissModally() {
        Logger.main.tag(tag).info("dismissing modal")
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // Mark: - UITextViewDelegate
    
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
    
}
