//
//  AddIssuerViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/13/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import BlockchainCertificates

class AddIssuerViewController: UIViewController {
    private var inProgressRequest : CommonRequest?
    var delegate : AddIssuerViewControllerDelegate?
    
    var identificationURL: URL?
    var nonce: String?
    
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
        view.backgroundColor = Colors.baseColor
        
        title = "Add Issuer"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveIssuerTapped(_:)))
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = Colors.brandColor
        navigationController?.navigationBar.tintColor = Colors.tintColor
        navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: Colors.tintColor
        ]
        
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
                field.tintColor = Colors.brandColor
                field.selectedTitleColor = Colors.primaryTextColor
                field.textColor = Colors.primaryTextColor
                field.font = Fonts.brandFont

                field.lineColor = Colors.placeholderTextColor
                field.selectedLineHeight = 1
                field.selectedLineColor = Colors.brandColor
                
                field.placeholderColor = Colors.placeholderTextColor
                field.placeholderFont = Fonts.placeholderFont
            }
        }
        
        let labels = [
            issuerURLLabel,
            identityInformationLabel
        ]
        labels.forEach { (label) in
            label?.textColor = Colors.primaryTextColor
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
        isLoading = true
        managedIssuer.getIssuerIdentity(from: url) { [weak self] isSuccessful in
            
            guard isSuccessful else {
                // TODO: Somehow alert/convey that this isn't a valid issuer.
                self?.isLoading = false
                return
            }
            
            // At this point, we have an issuer, se we'll definitely be dismissing, even if the introduction step fails.
            if let nonce = self?.nonce {
                managedIssuer.introduce(recipient: targetRecipient, with: nonce) { (success) in
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
