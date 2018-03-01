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

class AddIssuerViewController: UIViewController {
    private var inProgressRequest : CommonRequest?
    var delegate : AddIssuerViewControllerDelegate?
    
    var identificationURL: URL?
    var nonce: String?
    var managedIssuer: ManagedIssuer?
    
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var issuerURLField: UITextView!
    @IBOutlet weak var nonceField : UITextView!
    
    var isLoading = false {
        didSet {
        }
    }
    
    init(identificationURL: URL? = nil, nonce: String? = nil) {
        self.identificationURL = identificationURL
        self.nonce = nonce
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Add an Issuer", comment: "Navigation title for the 'Add Issuer' form.")
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = Style.Color.C3
        
        issuerURLField.delegate = self
        nonceField.delegate = self
        
        loadDataIntoFields()
        stylize()
        
        // No need to unregister these. Thankfully.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }
    
    func loadDataIntoFields() {
        issuerURLField.text = identificationURL?.absoluteString
        nonceField.text = nonce
    }
    
    func saveDataIntoFields() {
        guard let urlString = issuerURLField.text else {
            // TODO: Somehow alert/convey the fact that this field is required.
            return
        }
        guard let url = URL(string: urlString) else {
            // TODO: Somehow alert/convey that this isn't a valid URL
            return
        }
        identificationURL = url
        nonce = nonceField.text
    }
    
    func stylize() { }

    @IBAction func addIssuerTapped(_ sender: Any) {
        Logger.main.info("Save issuer tapped")
        
        // TODO: validation.
        
        saveDataIntoFields()
        
        guard identificationURL != nil,
            nonce != nil else {
                return
        }
        
        identifyAndIntroduceIssuer(at: identificationURL!)
    }

    @objc func cancelTapped(_ sender: UIBarButtonItem) {
        Logger.main.info("Cancel Add Issuer tapped")
        
        dismiss(animated: true, completion: nil)
    }
    
    func autoSubmitIfPossible() {
        loadDataIntoFields()
        
        let areAllFieldsFilled = identificationURL != nil && nonce != nil

        if areAllFieldsFilled {
            identifyAndIntroduceIssuer(at: identificationURL!)
        }
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
    
    func identifyAndIntroduceIssuer(at url: URL) {
        Logger.main.info("Starting process to identify and introduce issuer at \(url)")
        
        cancelWebLogin()
        
        let targetRecipient = Recipient(givenName: "",
                                        familyName: "",
                                        identity: "",
                                        identityType: "email",
                                        isHashed: false,
                                        publicAddress: Keychain.shared.nextPublicAddress(),
                                        revocationAddress: nil)
        
        let managedIssuer = ManagedIssuer()
        self.managedIssuer = managedIssuer
        isLoading = true
        managedIssuer.getIssuerIdentity(from: url) { [weak self] identifyError in
            guard identifyError == nil else {
                self?.isLoading = false
                
                var failureReason = NSLocalizedString("Something went wrong adding this issuer. Try again later.", comment: "Generic error for failure to add an issuer")
                
                switch(identifyError!) {
                case .invalidState(let reason):
                    // This is a developer error, so write it to the log so we can see it later.
                    Logger.main.fatal("Invalid ManagedIssuer state: \(reason)")
                    failureReason = NSLocalizedString("The app is in an invalid state. Please quit the app & relaunch. Then try again.", comment: "Invalid state error message when adding an issuer.")
                case .untrustworthyIssuer:
                    failureReason = NSLocalizedString("This issuer appears to have been tampered with. Please contact the issuer.", comment: "Error message when the issuer's data doesn't match the URL it's hosted at.")
                case .abortedIntroductionStep:
                    failureReason = NSLocalizedString("The request was aborted. Please try again.", comment: "Error message when an identification request is aborted")
                case .serverErrorDuringIdentification(let code, let message):
                    Logger.main.error("Error during issuer identification: \(code) \(message)")
                    failureReason = NSLocalizedString("The server encountered an error. Please try again.", comment: "Error message when an identification request sees a server error")
                case .serverErrorDuringIntroduction(let code, let message):
                    Logger.main.error("Error during issuer introduction: \(code) \(message)")
                    failureReason = NSLocalizedString("The server encountered an error. Please try again.", comment: "Error message when an identification request sees a server error")
                case .issuerInvalid(_, scope: .json):
                    failureReason = NSLocalizedString("We couldn't understand this Issuer's response. Please contact the Issuer.", comment: "Error message displayed when we see missing or invalid JSON in the response.")
                case .issuerInvalid(reason: .missing, scope: .property(let named)):
                    failureReason = String.init(format: NSLocalizedString("Issuer responded, but didn't include the \"%@\" property", comment: "Format string for an issuer response with a missing property. Variable is the property name that's missing."), named)
                case .issuerInvalid(reason: .invalid, scope: .property(let named)):
                    failureReason = String.init(format: NSLocalizedString("Issuer responded, but it contained an invalid property named \"%@\"", comment: "Format string for an issuer response with an invalid property. Variable is the property name that's invalid."), named)
                default: break
                }
                
                self?.showAddIssuerError(message: failureReason)

                return
            }
            
            Logger.main.info("Issuer identification at \(url) succeeded. Beginning introduction step.")
            
            if let nonce = self?.nonce {
                managedIssuer.delegate = self
                managedIssuer.introduce(recipient: targetRecipient, with: nonce) { introductionError in
                    guard introductionError == nil else {
                        self?.showAddIssuerError(withManagedIssuerError: introductionError!)
                        return
                    }
                    
                    self?.notifyAndDismiss(managedIssuer: managedIssuer)
                }
            } else {
                self?.showAddIssuerError(message: NSLocalizedString("We've encountered an error state when trying to talk to the issuer. Please try again.", comment: "Generic error when we've begun to introduce, but we don't have a nonce."))
            }
        }
    }
    
    @IBAction func cancelLoadingTapped(_ sender: Any) {
        Logger.main.info("Cancel Loading tapped.")
        
        managedIssuer?.abortRequests()
        isLoading = false
    }
    
    func notifyAndDismiss(managedIssuer: ManagedIssuer) {
        delegate?.added(managedIssuer: managedIssuer)
        
        DispatchQueue.main.async { [weak self] in
            
            let title = NSLocalizedString("Success!", comment: "Add issuers alert title")
            let message = NSLocalizedString("An isser was added. Please check your issuers screen.", comment: "Add issuer alert message")
            let okay = NSLocalizedString("Okay", comment: "OK dismiss action")
            let alert = AlertViewController.create(title: title, message: message, icon: .success, buttonText: okay)
            if let button = alert.buttons.first {
                button.onTouchUpInside { [weak self] in
                    self?.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            }
            self?.isLoading = false
            self?.present(alert, animated: false, completion: nil)
        }
    }
    
    func showAddIssuerError(withManagedIssuerError error: ManagedIssuerError) {
        var failureReason : String?
        
        switch error {
        case .invalidState(let reason):
            // This is a developer error, so write it to the log so we can see it later.
            Logger.main.fatal("Invalid ManagedIssuer state: \(reason)")
            failureReason = NSLocalizedString("The app is in an invalid state. Please quit the app & relaunch. Then try again.", comment: "Invalid state error message when adding an issuer.")
        case .untrustworthyIssuer:
            failureReason = NSLocalizedString("This issuer appears to have been tampered with. Please contact the issuer.", comment: "Error message when the issuer's data doesn't match the URL it's hosted at.")
        case .abortedIntroductionStep:
            failureReason = nil //NSLocalizedString("The request was aborted. Please try again.", comment: "Error message when an identification request is aborted")
        case .serverErrorDuringIdentification(let code, let message):
            Logger.main.error("Issuer identification failed with code: \(code) error: \(message)")
            failureReason = NSLocalizedString("The server encountered an error. Please try again.", comment: "Error message when an identification request sees a server error")
        case .serverErrorDuringIntroduction(let code, let message):
            Logger.main.error("Issuer introduction failed with code: \(code) error: \(message)")
            failureReason = NSLocalizedString("The server encountered an error. Please try again.", comment: "Error message when an identification request sees a server error")
        case .issuerInvalid(_, scope: .json):
            failureReason = NSLocalizedString("We couldn't understand this Issuer's response. Please contact the Issuer.", comment: "Error message displayed when we see missing or invalid JSON in the response.")
        case .issuerInvalid(reason: .missing, scope: .property(let named)):
            failureReason = String.init(format: NSLocalizedString("Issuer responded, but didn't include the \"%@\" property", comment: "Format string for an issuer response with a missing property. Variable is the property name that's missing."), named)
        case .issuerInvalid(reason: .invalid, scope: .property(let named)):
            failureReason = String.init(format: NSLocalizedString("Issuer responded, but it contained an invalid property named \"%@\"", comment: "Format string for an issuer response with an invalid property. Variable is the property name that's invalid."), named)
        case .authenticationFailure:
            Logger.main.error("Failed to authenticate the user to the issuer. Either because of a bad nonce or a failed web auth.")
            failureReason = NSLocalizedString("We couldn't authenticate you to the issuer. Double-check your one-time code and try again.", comment: "This error is presented when the user uses a bad nonce")
        case .genericError(let error, let data):
            var message : String?
            if data != nil {
                message = String(data: data!, encoding: .utf8)
            }
            Logger.main.error("Generic error during add issuer: \(error?.localizedDescription ?? "none"), data: \(message ?? "none")")
            failureReason = NSLocalizedString("Adding this issuer failed. Please try again", comment: "Generic error when adding an issuer.")
        default:
            failureReason = nil
        }
        
        if let message = failureReason {
            showAddIssuerError(message: message)
        }
    }
    
    func showAddIssuerError(message: String) {
        Logger.main.info("Add issuer failed with message: \(message)")
        
        let title = NSLocalizedString("Add Issuer Failed", comment: "Alert title when adding an issuer fails for any reason.")

        let alert = AlertViewController.createWarning(title: title, message: message)
        
        isLoading = false
        
        OperationQueue.main.addOperation {
            if self.presentedViewController != nil {
                self.presentedViewController?.dismiss(animated: true, completion: { 
                    self.present(alert, animated: false, completion: nil)
                })
            } else {
                self.present(alert, animated: false, completion: nil)
            }
        }
    }
}

extension AddIssuerViewController : ManagedIssuerDelegate {
    func presentWebView(at url: URL, with navigationDelegate: WKNavigationDelegate) throws {
        Logger.main.info("Presenting the web view in the Add Issuer screen.")
        
        let webController = WebLoginViewController(requesting: url, navigationDelegate: navigationDelegate) { [weak self] in
            self?.cancelWebLogin()
        }
        let navigationController = UINavigationController(rootViewController: webController)
        
        OperationQueue.main.addOperation {
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    func dismissWebView() {
        OperationQueue.main.addOperation { [weak self] in
            self?.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func cancelWebLogin() {
        managedIssuer?.abortRequests()
        isLoading = false
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
}
