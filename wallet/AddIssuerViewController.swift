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
    
    
    @IBOutlet weak var issuerURLField: UITextField!
    
    public init() {
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
        
        let managedIssuer = ManagedIssuer()
        managedIssuer.getIssuerIdentity(from: url) { [weak self] isSuccessful in
            guard isSuccessful else {
                // TODO: Somehow alert/convey that this isn't a valid issuer.
                return
            }
            self?.delegate?.added(managedIssuer: managedIssuer)
            self?.dismiss(animated: true, completion: nil)
        }
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
}


protocol AddIssuerViewControllerDelegate : class {
    func added(managedIssuer: ManagedIssuer)
}
