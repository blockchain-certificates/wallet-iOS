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
    var firstName : String!
    var lastName : String!
    var email : String!
    
    var identificationURL: URL?
    var nonce: String?
    
    @IBOutlet weak var issuerURLField: UITextField!
    
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

        // Do any additional setup after loading the view.
        fetchAccountData()
    }

    @IBAction func saveIssuerTapped(_ sender: UIBarButtonItem) {
        guard let urlString = issuerURLField.text else {
            // TODO: Somehow alert/convey the fact that this field is required.
            return
        }
        guard let url = URL(string: urlString) else {
            // TODO: Somehow alert/convey that this isn't a valid URL
            return
        }
        
        identifyAndIntroduceIssuer(at: url)
    }

    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    
    func fetchAccountData() {
        guard let firstName = UserDefaults.standard.string(forKey: UserKeys.firstNameKey),
            let lastName = UserDefaults.standard.string(forKey: UserKeys.lastNameKey),
            let email = UserDefaults.standard.string(forKey: UserKeys.emailKey) else {
                // TODO: Redirect the user to the Add Account page, since they don't have an account.
                return
        }
        
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
    
    func autoSubmitIfPossible() {
        issuerURLField.text = self.identificationURL?.absoluteString
        
        // TODO: Show the nonce
        
        let areAllFieldsFilled = firstName != nil && lastName != nil && email != nil && identificationURL != nil

        if areAllFieldsFilled {
            identifyAndIntroduceIssuer(at: identificationURL!)
        }
    }
    
    func identifyAndIntroduceIssuer(at url: URL) {
        let targetRecipient = Recipient(givenName: firstName,
                                        familyName: lastName,
                                        identity: email,
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
