//
//  RevealPassphraseTableViewController.swift
//  wallet
//
//  Created by Chris Downie on 1/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import LocalAuthentication


private let cellReuseIdentifier = "UITableViewCell"

enum AuthErrors : Error {
    case noAuthMethodAllowed
}

class RevealPassphraseTableViewController: UITableViewController {
    private var hasAuthenticated = false
    private var specificAuthenticationError : String? = nil
    
    convenience init() {
        self.init(style: .grouped)
    }
    
    override init(style: UITableViewStyle) {
        // ignore input. This view is always the grouped style
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        title = "Passphrase"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        authenticate()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        if hasAuthenticated {
            cell.textLabel?.text = Keychain.shared.seedPhrase
            cell.selectionStyle = .none
            cell.textLabel?.textColor = .black
        } else {
            cell.textLabel?.text = "Show Passphrase"
            cell.selectionStyle = .default
            cell.textLabel?.textColor = Colors.brandColor
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && hasAuthenticated {
            return "Information"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 && !hasAuthenticated {
            let genericError = "Please try to authenticate again to see your passphrase."
            
            if let details = specificAuthenticationError {
                return "\(details)\n\n\(genericError)"
            } else {
                return genericError
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !hasAuthenticated else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        if indexPath.section == 0 && indexPath.row == 0 {
            authenticate()
        }
    }
    
    // MARK: - Actual interaction stuff.
    func authenticate() {
        authenticateUser { (success, error) in
            defer {
                OperationQueue.main.addOperation {
                    self.tableView.reloadData()
                }
            }
            
            self.hasAuthenticated = success
            
            guard success else {
                guard let error = error else {
                    return
                }
                
                switch error {
                case AuthErrors.noAuthMethodAllowed:
                    self.specificAuthenticationError = "It looks like local authentication is disabled for this app. Without it, showing your passphrase would be insecure. Please enable local authentication for this app in Settings"
                default:
                    self.specificAuthenticationError = nil
                }
                
                dump(error)
                return
            }
            

        }
    }
    
    func authenticateUser(completionHandler: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error : NSError? = nil
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to see your secure passphrase.", reply: completionHandler)
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Authenticate to see your secure passphrase.",
                reply: completionHandler)
        } else {
            completionHandler(false, AuthErrors.noAuthMethodAllowed)
        }
    }
}
