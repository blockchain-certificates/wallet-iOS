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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Add a Credential", comment: "Title in settings")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.instance.styleApplicationDefault()
    }
    
    // MARK: - Add Credential
    
    @IBAction func importFromURL() {
        Logger.main.info("Add Credential from URL tapped in settings")
        let storyboard = UIStoryboard(name: "Settings", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "addCredentialFromURL") as! AddCredentialURLViewController
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func importFromFile() {
        Logger.main.info("User has chosen to add a certificate from file")
        
        let controller = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
        controller.delegate = self
        controller.modalPresentationStyle = .formSheet
        
        AppDelegate.instance.styleApplicationAlternate()
        present(controller, animated: true, completion: nil)
    }
    
    func importCertificate(from data: Data?) {
        guard let data = data else {
            Logger.main.error("Failed to load a certificate from file. Data is nil.")
            
            let title = NSLocalizedString("Invalid Credential", comment: "Imported certificate didn't parse title")
            let message = NSLocalizedString("That doesn't appear to be a valid credential file.", comment: "Imported title didn't parse message")
            alertError(localizedTitle: title, localizedMessage: message)
            return
        }
        
        do {
            let certificate = try CertificateParser.parse(data: data)
            saveCertificateIfOwned(certificate: certificate)
            
            alertSuccess(callback: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
        } catch {
            Logger.main.error("Importing failed with error: \(error)")
            
            let title = NSLocalizedString("Invalid Credential", comment: "Imported certificate didn't parse title")
            let message = NSLocalizedString("That doesn't appear to be a valid credential file.", comment: "Imported title didn't parse message")
            alertError(localizedTitle: title, localizedMessage: message)
            return
        }
    }
    
    func saveCertificateIfOwned(certificate: Certificate) {
        guard !userCancelledAction else { return }
        let manager = CertificateManager()
        manager.save(certificate: certificate)
    }
    
    var userCancelledAction = false
    
    // User tapped cancel in progress alert
    func cancelAddCredential() {
        userCancelledAction = true
        hideActivityIndicator()
    }
    
    func showActivityIndicator() {
        userCancelledAction = false
        
        let title = NSLocalizedString("Adding Credential", comment: "Progress alert title")
        let message = NSLocalizedString("Please wait while your credential is added.", comment: "Progress alert message while adding a credential")
        let cancel = NSLocalizedString("Cancel", comment: "Button copy")
        
        let alert = AlertViewController.create(title: title, message: message, icon: .verifying, buttonText: cancel)
        
        alert.buttons.first?.onTouchUpInside { [weak self] in
            self?.cancelAddCredential()
        }
        
        present(alert, animated: false, completion: nil)
    }
    
    func hideActivityIndicator() {
        presentedViewController?.dismiss(animated: false, completion: nil)
    }
    
    func alertError(localizedTitle: String, localizedMessage: String) {
        hideActivityIndicator()
        
        let okay = NSLocalizedString("Okay", comment: "OK dismiss action")
        let alert = AlertViewController.create(title: localizedTitle, message: localizedMessage, icon: .warning, buttonText: okay)
        present(alert, animated: false, completion: nil)
    }
    
    func alertSuccess(callback: (() -> Void)?) {
        hideActivityIndicator()
        
        let title = NSLocalizedString("Success!", comment: "Alert title")
        let message = NSLocalizedString("A credential was imported. Please check your credentials screen.", comment: "Successful credential import from URL in settings alert message")
        let okay = NSLocalizedString("Okay", comment: "OK dismiss action")
        let alert = AlertViewController.create(title: title, message: message, icon: .success, buttonText: okay)
        alert.buttons.first?.onTouchUpInside { callback?() }
        present(alert, animated: false, completion: nil)
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let data = try? Data(contentsOf: url)
        importCertificate(from: data)
    }
    
}

class AddCredentialURLViewController: AddCredentialViewController, UITextViewDelegate {
    
    @IBOutlet weak var urlTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    
    // closure called when presented modally and credential successfully added
    var successCallback: ((Certificate) -> ())?
    var presentedModally = false
    
    @IBAction func importURL() {
        guard let urlString = urlTextView.text,
            let url = URL(string: urlString.trimmingCharacters(in: CharacterSet.whitespaces)) else {
                return
        }
        Logger.main.info("User attempting to add a certificate from \(url).")
        
        addCertificate(from: url)
    }
    
    func addCertificate(from url: URL) {
        urlTextView.resignFirstResponder()
        showActivityIndicator()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let certificate = CertificateManager().load(certificateAt: url) else {
                DispatchQueue.main.async { [weak self] in
                    Logger.main.error("Failed to load certificate from \(url)")
                    
                    let title = NSLocalizedString("Invalid Credential", comment: "Title for an alert when importing an invalid certificate")
                    let message = NSLocalizedString("That file doesn't appear to be a valid credential.", comment: "Message in an alert when importing an invalid certificate")
                    self?.alertError(localizedTitle: title, localizedMessage: message)
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard !(self?.userCancelledAction ?? false) else { return }
                self?.saveCertificateIfOwned(certificate: certificate)
                
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
        urlTextView.backgroundColor = Style.Color.C10
        urlTextView.text = ""
        urlTextView.delegate = self
        urlTextView.font = Style.Font.T3S
        urlTextView.textColor = Style.Color.C3
        submitButton.isEnabled = false
    }
    
    @objc func dismissModally() {
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
