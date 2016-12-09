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
    var firstName : String?
    var lastName : String?
    var emailAddress : String?
    var nonce: String?
    
    @IBOutlet weak var issuerURLField: UITextField!
    
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailAddressField : UITextField!
    @IBOutlet weak var nonceField : UITextField!
    
    
    init(identificationURL: URL? = nil, nonce: String? = nil) {
        self.identificationURL = identificationURL
        self.nonce = nonce
        firstName = UserDefaults.standard.string(forKey: UserKeys.firstNameKey)
        lastName = UserDefaults.standard.string(forKey: UserKeys.lastNameKey)
        emailAddress = UserDefaults.standard.string(forKey: UserKeys.emailKey)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Issuer"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveIssuerTapped(_:)))
        
        navigationController?.navigationBar.barTintColor = Colors.translucentBrandColor
        navigationController?.navigationBar.tintColor = Colors.tintColor
        navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: Colors.tintColor
        ]
        
        loadDataIntoFields()
    }
    
    func loadDataIntoFields() {
        issuerURLField.text = identificationURL?.absoluteString
        
        firstNameField.text = firstName
        lastNameField.text = lastName
        emailAddressField.text = emailAddress
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
        firstName = firstNameField.text
        lastName = lastNameField.text
        emailAddress = emailAddressField.text
        nonce = nonceField.text
    }

    func saveIssuerTapped(_ sender: UIBarButtonItem) {
        // TODO: validation.
        
        saveDataIntoFields()
        
        guard identificationURL != nil,
            firstName != nil,
            lastName != nil,
            emailAddress != nil,
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
        
        let areAllFieldsFilled = firstName != nil && lastName != nil && emailAddress != nil && identificationURL != nil

        if areAllFieldsFilled {
            identifyAndIntroduceIssuer(at: identificationURL!)
        }
    }
    
    func identifyAndIntroduceIssuer(at url: URL) {
        let targetRecipient = Recipient(givenName: firstName!,
                                        familyName: lastName!,
                                        identity: emailAddress!,
                                        identityType: "email",
                                        isHashed: false,
                                        publicAddress: Keychain.shared.nextPublicAddress(),
                                        revocationAddress: nil)
        
        let managedIssuer = ManagedIssuer()
        managedIssuer.getIssuerIdentity(from: url) { [weak self] isSuccessful in
            guard isSuccessful else {
                // TODO: Somehow alert/convey that this isn't a valid issuer.
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
    
    func notifyAndDismiss(managedIssuer: ManagedIssuer) {
        delegate?.added(managedIssuer: managedIssuer)
        
        OperationQueue.main.addOperation { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}


protocol AddIssuerViewControllerDelegate : class {
    func added(managedIssuer: ManagedIssuer)
}
