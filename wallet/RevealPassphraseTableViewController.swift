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
private let labeledCellReuseIdentifier = "LabeledTableViewCell"

enum AuthErrors : Error {
    case noAuthMethodAllowed
}

class RevealPassphraseTableViewController: UITableViewController {
    private let copySelector : Selector = #selector(copy(_:))
    
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
        title = NSLocalizedString("Passphrase", comment: "Navigation title for revealing the current passphrase.")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.register(LabeledTableViewCell.self, forCellReuseIdentifier: labeledCellReuseIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.backgroundColor = .baseColor
        
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
        let cell : UITableViewCell!
        if hasAuthenticated {
            let labeledCell = tableView.dequeueReusableCell(withIdentifier: labeledCellReuseIdentifier) as! LabeledTableViewCell
            labeledCell.titleLabel.text = NSLocalizedString("Current Passphrase", comment: "Label for the current passphrase.")
            labeledCell.contentLabel.text = Keychain.shared.seedPhrase
            
            cell = labeledCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
            cell.textLabel?.text = NSLocalizedString("Show Passphrase", comment: "Action button for revealing the current passphrase")
            cell.selectionStyle = .default
            cell.textLabel?.textColor = .brandColor
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && hasAuthenticated {
            return NSLocalizedString("Information", comment: "Information about the passphrase")
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 && !hasAuthenticated {
            let genericError = NSLocalizedString("Please try to authenticate again to see your passphrase.", comment: "Generic authentication failure error.")
            
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
    
    // Mark: Copy/pasting content
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        guard hasAuthenticated else {
            return false
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        guard hasAuthenticated else {
            return false
        }
        return action == copySelector
    }
    
    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        guard hasAuthenticated && action == copySelector else {
            return
        }
        
        UIPasteboard.general.string = Keychain.shared.seedPhrase
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
                    self.specificAuthenticationError = NSLocalizedString("It looks like local authentication is disabled for this app. Without it, showing your passphrase is insecure. Please enable local authentication for this app in Settings.", comment: "Specific authentication error: The user's phone has local authentication disabled, so we can't show the passphrase.")
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
        let reason = NSLocalizedString("Authenticate to see your secure passphrase.", comment: "Prompt to authenticate in order to reveal their passphrase.")
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply: completionHandler)
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason,
                reply: completionHandler)
        } else {
            completionHandler(false, AuthErrors.noAuthMethodAllowed)
        }
    }
}
