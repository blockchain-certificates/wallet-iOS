//
//  SettingsTableViewController.swift
//  wallet
//
//  Created by Chris Downie on 1/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts
import LocalAuthentication

enum AuthErrors : Error {
    case noAuthMethodAllowed
}

class SettingsCell : UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryView  = UIImageView(image: #imageLiteral(resourceName: "icon_disclosure"))
        isAccessibilityElement = true
        textLabel?.font = Style.Font.T3S
        textLabel?.textColor = Style.Color.C6
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SettingsTableViewController: UITableViewController {
    private var oldBarStyle : UIBarStyle?

    private let cellReuseIdentifier = "UITableViewCell"
    
    #if DEBUG
        private let isDebugBuild = true
    #else
        private let isDebugBuild = false
    #endif

    convenience init() {
        self.init(style: .grouped)
    }
    
    override init(style: UITableViewStyle) {
        // ignore input. This view is always the grouped style
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    // Mark: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        clearsSelectionOnViewWillAppear = true
        title = Localizations.Settings
        
        let cancelButton = UIBarButtonItem(image: #imageLiteral(resourceName: "icon_close"), style: .done, target: self, action: #selector(dismissSettings))
        cancelButton.accessibilityLabel = Localizations.Close
        navigationItem.rightBarButtonItem = cancelButton
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        tableView.register(SettingsCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.backgroundColor = Style.Color.C2
        tableView.rowHeight = 56
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.styleDefault()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let selectedPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedPath, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        var barStyle = UIBarStyle.default
        if let oldBarStyle = oldBarStyle {
            barStyle = oldBarStyle
        }
        
        navigationController?.navigationBar.barStyle = barStyle
    }

    @objc func dismissSettings() {
        Logger.main.info("Dismissing the settings screen.")
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isDebugBuild ? 10 : 6
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        
        let text : String?
        switch indexPath.row {
        case 0:
            text = Localizations.AddIssuer
        case 1:
            text = Localizations.AddCredential
        case 2:
            text = Localizations.MyPassphrase
        case 3:
            text = Localizations.AboutPassphrases
        case 4:
            text = Localizations.PrivacyPolicy
        case 5:
            text = Localizations.EmailLogs
        // The following are only visible in DEBUG builds
        case 6:
            text = "[DEBUG] Destroy passphrase & crash"
        case 7:
            text = "[DEBUG] Delete issuers & certificates"
        case 8:
            text = "[DEBUG] Destroy all data & crash"
        case 9:
            text = "[DEBUG] Show onboarding"
        default:
            text = nil
        }
        
        cell.textLabel?.text = text
        cell.accessibilityLabel = text

        return cell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var controller : UIViewController?
        var configuration : AppConfiguration?
        
        switch indexPath.row {
        case 0:
            Logger.main.info("Add Issuer tapped in settings")
            showAddIssuerFlow()
        case 1:
            Logger.main.info("Add Credential tapped in settings")
            let storyboard = UIStoryboard(name: "Settings", bundle: Bundle.main)
            controller = storyboard.instantiateViewController(withIdentifier: "addIssuer") as! AddCredentialViewController
        case 2:
            Logger.main.info("My passphrase tapped in settings")
            authenticate()
            controller = nil
        case 3:
            Logger.main.info("About passphrase tapped in settings")
            controller = AboutPassphraseViewController()
        case 4:
            Logger.main.info("Privacy statement tapped in settings")
            controller = PrivacyViewController()
        case 5:
            Logger.main.info("Share device logs")
            controller = nil
            shareLogs()
            
        // The following are only visible in DEBUG builds
        case 6:
            Logger.main.info("Destroy passphrase & crash...")
            configuration = AppConfiguration(shouldDeletePassphrase: true, shouldResetAfterConfiguring: true)
        case 7:
            Logger.main.info("Delete all issuers & certificates...")
            configuration = AppConfiguration(shouldDeleteIssuersAndCertificates: true)
            tableView.deselectRow(at: indexPath, animated: true)
        case 8:
            Logger.main.info("Delete all data & crash...")
            configuration = AppConfiguration.resetEverything
        case 9:
            let storyboard = UIStoryboard(name: "Onboarding", bundle: Bundle.main)
            present(storyboard.instantiateInitialViewController()!, animated: false, completion: nil)
        default:
            controller = nil
        }
        
        if let newAppConfig = configuration {
            try! ConfigurationManager().configure(with: newAppConfig)
        }
        
        if let controller = controller {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func deleteIssuersAndCertificates() {
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(atPath: Paths.certificatesDirectory.path)
            for filePath in filePaths {
                try FileManager.default.removeItem(at: Paths.certificatesDirectory.appendingPathComponent(filePath))
            }
        } catch {
            Logger.main.warning("Could not clear temp folder: \(error)")
        }
        
        do {
            try FileManager.default.removeItem(at: Paths.issuersNSCodingArchiveURL)
        } catch {
            Logger.main.warning("Could not delete NSCoding-based issuer list: \(error)")
        }
        
        do {
            try FileManager.default.removeItem(at: Paths.managedIssuersListURL)
        } catch {
            Logger.main.warning("Could not delete managed issuers list: \(error)")
        }
    }
    
    func shareLogs() {
        guard let shareURL = try? Logger.main.shareLogs() else {
            Logger.main.error("Sharing the logs failed. Not sure how we'll ever get this information back to you. ¯\\_(ツ)_/¯")
            
            let alert = AlertViewController.createWarning(title: Localizations.FileNotFound, message: Localizations.DeviceMissingLogs, buttonText: Localizations.Okay)
            present(alert, animated: false, completion: { [weak self] in
                self?.deselectRow()
            })
            
            return
        }
        
        // TODO: set recipient to techsupport@learningmachine.com
        let items : [Any] = [ shareURL ]
        let shareController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        present(shareController, animated: true, completion: { [weak self] in
            self?.deselectRow()
            self?.navigationController?.styleAlternate()
        })
    }
    
    func clearLogs() {
        Logger.main.clearLogs()
        
        let alert = AlertViewController.create(title: Localizations.Success, message: Localizations.DeleteLogsSuccess, icon: .success, buttonText: Localizations.Okay)
        present(alert, animated: false, completion: { [weak self] in
            self?.deselectRow()
        })
    }
    
    func deselectRow() {
        if let indexPath = tableView.indexPathForSelectedRow {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    // MARK: - Add Issuer
    
    func showAddIssuerFlow() {
        let controller = AddIssuerViewController()
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
    // MARK: - User Authentication (TouchID/FaceID)
    
    func authenticate() {
        defer {
            if let selectionIndexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectionIndexPath, animated: true)
            }
        }
        
        authenticateUser { [weak self] (success, error) in
            
            guard success else {
                guard let error = error else {
                    return
                }
                
                switch error { //TODO: Fix
                case AuthErrors.noAuthMethodAllowed:
                    DispatchQueue.main.async { [weak self] in
                        let alert = AlertViewController.create(title: Localizations.ProtectYourPassphrase,
                                                               message: Localizations.EnableAuthenticationPrompt, icon: .warning, buttonText: Localizations.Okay)
                        self?.present(alert, animated: false, completion: nil)
                    }
                default:
                    // self.specificAuthenticationError = nil
                    break
                }
                
                dump(error)
                return
            }
            
            // Successful authentication - show the users's passphrase
            DispatchQueue.main.async { [weak self] in
                let storyboard = UIStoryboard(name: "Onboarding", bundle: Bundle.main)
                let controller = storyboard.instantiateViewController(withIdentifier: "MyPassphrase")
                self?.navigationController?.pushViewController(controller, animated: true)
            }
        }
        
    }
    
    func authenticateUser(completionHandler: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error : NSError? = nil
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: Localizations.AuthenticateSeePassphrase, reply: completionHandler)
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: Localizations.AuthenticateSeePassphrase,
                reply: completionHandler)
        } else {
            completionHandler(false, AuthErrors.noAuthMethodAllowed)
        }
    }
}

extension SettingsTableViewController: AddIssuerViewControllerDelegate {
    func added(managedIssuer: ManagedIssuer) {
        if managedIssuer.issuer != nil {
            let manager = ManagedIssuerManager()
            let managedIssuers = manager.load()
            let updatedIssuers = managedIssuers.filter{ $0.issuer?.id != managedIssuer.issuer?.id } + [managedIssuer]
            _ = manager.save(updatedIssuers)
        } else {
            Logger.main.warning("Something weird -- delegate called with nil issuer. \(#function)")
        }
    }
}
