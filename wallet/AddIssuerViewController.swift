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
    
    @IBOutlet weak var issuerURLLabel: UILabel!
    @IBOutlet weak var issuerURLField: UITextField!
    
    @IBOutlet weak var identityInformationLabel : UILabel!
    @IBOutlet weak var nonceField : UITextField!
    
    var isLoading = false {
        didSet {
            if loadingView != nil {
                OperationQueue.main.addOperation { [weak self] in
                    self?.loadingView.isHidden = !(self?.isLoading)!
                }
            }
        }
    }
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingStatusLabel : UILabel!
    @IBOutlet weak var loadingCancelButton : UIButton!

    
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
        view.backgroundColor = .baseColor
        
        title = NSLocalizedString("Add Issuer", comment: "Navigation title for the 'Add Issuer' form.")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveIssuerTapped(_:)))
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .brandColor
        
        loadingView.isHidden = !isLoading
        
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
    
    func stylize() {
        let fields = [
            issuerURLField,
            nonceField
        ]
        
        fields.forEach { (textField) in
            if let field = textField as? SkyFloatingLabelTextField {
                field.tintColor = .tintColor
                field.selectedTitleColor = .primaryTextColor
                field.textColor = .primaryTextColor
                field.font = Fonts.brandFont

                field.lineColor = .placeholderTextColor
                field.selectedLineHeight = 1
                field.selectedLineColor = .tintColor
                
                field.placeholderColor = .placeholderTextColor
                field.placeholderFont = Fonts.placeholderFont
            }
        }
        
        let labels = [
            issuerURLLabel,
            identityInformationLabel
        ]
        labels.forEach { (label) in
            label?.textColor = .primaryTextColor
        }
    }

    func saveIssuerTapped(_ sender: UIBarButtonItem) {
        // TODO: validation.
        
        saveDataIntoFields()
        
        guard identificationURL != nil,
            nonce != nil else {
                return
        }
        
        identifyAndIntroduceIssuer(at: identificationURL!)
    }

    func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func autoSubmitIfPossible() {
        loadDataIntoFields()
        
        let areAllFieldsFilled = identificationURL != nil && nonce != nil

        if areAllFieldsFilled {
            identifyAndIntroduceIssuer(at: identificationURL!)
        }
    }
    
    func keyboardDidShow(notification: NSNotification) {
        guard let info = notification.userInfo,
            let keyboardRect = info[UIKeyboardFrameBeginUserInfoKey] as? CGRect else {
            return
        }

        let scrollInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardRect.size.height, right: 0)
        scrollView.contentInset = scrollInsets
        scrollView.scrollIndicatorInsets = scrollInsets
    }
    
    func keyboardDidHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    func identifyAndIntroduceIssuer(at url: URL) {
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
                    print("Invalid ManagedIssuer state: \(reason)")
                    failureReason = NSLocalizedString("The app is in an invalid state. Please quit the app & relaunch. Then try again.", comment: "Invalid state error message when adding an issuer.")
                case .untrustworthyIssuer:
                    failureReason = NSLocalizedString("This issuer appears to have been tampered with. Please contact the issuer.", comment: "Error message when the issuer's data doesn't match the URL it's hosted at.")
                case .abortedIntroductionStep:
                    failureReason = NSLocalizedString("The request was aborted. Please try again.", comment: "Error message when an identification request is aborted")
                case .serverError(let code):
                    print("Identification server error: \(code)")
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
            
            // At this point, we have an issuer, se we'll definitely be dismissing, even if the introduction step fails.
            if let nonce = self?.nonce {
                managedIssuer.delegate = self
                managedIssuer.introduce(recipient: targetRecipient, with: nonce) { introductionError in
                    self?.notifyAndDismiss(managedIssuer: managedIssuer)
                }
            } else {
                self?.notifyAndDismiss(managedIssuer: managedIssuer)
            }
        }
    }
    
    @IBAction func cancelLoadingTapped(_ sender: Any) {
        // TODO: This doesn't actually stop the in-flight request. Beacuse we can't do that yet.
        isLoading = false
    }
    
    func notifyAndDismiss(managedIssuer: ManagedIssuer) {
        delegate?.added(managedIssuer: managedIssuer)
        
        OperationQueue.main.addOperation { [weak self] in
            self?.isLoading = false
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    func showAddIssuerError(message: String) {
        let title = NSLocalizedString("Add Issuer Failed", comment: "Alert title when adding an issuer fails for any reason.")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Confirm action"), style: .cancel, handler: nil))
        
        OperationQueue.main.addOperation {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension AddIssuerViewController : ManagedIssuerDelegate {
    func present(webView: WKWebView) throws {
        OperationQueue.main.addOperation { // [weak self] in
            let webController = UIViewController()
            webController.view.addSubview(webView)
            webController.title = "Issuer Login"
            webController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelWebLogin))
            
            let views = [ "webView": webView ]
            var constraints = NSLayoutConstraint.constraints(withVisualFormat: "|[webView]|", options: .alignAllCenterX, metrics: nil, views: views)
            constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[webView]|", options: .alignAllCenterY, metrics: nil, views: views))
            webView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate(constraints)
            
            let navigationController = UINavigationController(rootViewController: webController)
        
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    func dismiss(webView: WKWebView) {
        OperationQueue.main.addOperation { [weak self] in
            self?.presentedViewController?.dismiss(animated: true, completion: nil)
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

extension AddIssuerViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let errorMessage : String? = nil
        
        switch textField {
        case issuerURLField:
            break;
        case nonceField:
            break;
        default:
            break;
        }
        
        if let field = textField as? SkyFloatingLabelTextField {
            field.errorMessage = errorMessage
        }
        return true
    }
    
    func validate(field : UITextField, options: ValidationOptions) -> String? {
        return nil
    }
}

protocol AddIssuerViewControllerDelegate : class {
    func added(managedIssuer: ManagedIssuer)
}
