//
//  SettingsTableViewController.swift
//  wallet
//
//  Created by Chris Downie on 1/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts

class SettingsCell : UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryView  = UIImageView(image: #imageLiteral(resourceName: "icon_disclosure"))
        textLabel?.font = Style.Font.T3S
        textLabel?.textColor = Style.Color.C6
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SettingsTableViewController: UITableViewController, UIDocumentPickerDelegate {
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
        // self.clearsSelectionOnViewWillAppear = false
        title = NSLocalizedString("Settings", comment: "Title of the Settings screen.")

        navigationController?.navigationBar.barTintColor = Style.Color.C3
        navigationController?.navigationBar.isTranslucent = false
        
        let cancelBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "CancelIcon"), landscapeImagePhone: #imageLiteral(resourceName: "CancelIcon"), style: .done, target: self, action: #selector(dismissSettings))
        navigationItem.leftBarButtonItem = cancelBarButton
        
        tableView.register(SettingsCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.backgroundColor = Style.Color.C2
        tableView.rowHeight = 56
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        oldBarStyle = navigationController?.navigationBar.barStyle
        navigationController?.navigationBar.barStyle = .default
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
        return isDebugBuild ? 11 : 7
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        
        let text : String?
        switch indexPath.row {
        case 0:
            text = NSLocalizedString("Add an Issuer", comment: "Action item in settings screen to add an Issuer manually.")
        case 1:
            text = NSLocalizedString("Add a Credential", comment: "Action item in settings screen to add an Issuer manually.")
        case 2:
            text = NSLocalizedString("My Passphrase", comment: "Action item in settings screen.")
        case 3:
            text = NSLocalizedString("About Passphrases", comment: "Menu action item for sharing device logs.")
        case 4:
            text = NSLocalizedString("Privacy Policy", comment: "Menu item in the settings screen that links to our privacy policy.")
        case 5:
            text = NSLocalizedString("Email Logs", comment: "Action item in settings screen.")
        case 6:
            text = NSLocalizedString("Log Out", comment: "Action item in settings screen.")
        // The following are only visible in DEBUG builds
        case 7:
            text = "Destroy passphrase & crash"
        case 8:
            text = "Delete all issuers & certificates"
        case 9:
            text = "Destroy all data & crash"
        case 10:
            text = "Show onboarding"
        default:
            text = nil
        }
        
        cell.textLabel?.text = text

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
            showAddCredentialFlow()
        case 2:
            Logger.main.info("My passphrase tapped in settings")
            controller = RevealPassphraseTableViewController()
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
        case 6:
            Logger.main.info("Share device logs")
            controller = nil
            // TODO: logout, probably with confirmation alert
            
        // The following are only visible in DEBUG builds
        case 7:
            Logger.main.info("Destroy passphrase & crash...")
            configuration = AppConfiguration(shouldDeletePassphrase: true, shouldResetAfterConfiguring: true)
        case 8:
            Logger.main.info("Delete all issuers & certificates...")
            configuration = AppConfiguration(shouldDeleteIssuersAndCertificates: true)
            tableView.deselectRow(at: indexPath, animated: true)
        case 9:
            Logger.main.info("Delete all data & crash...")
            configuration = AppConfiguration.resetEverything
        case 10:
            let storyboard = UIStoryboard(name: "Onboarding", bundle: Bundle.main)
            present(storyboard.instantiateInitialViewController()!, animated: false, completion: nil)
        default:
            controller = nil
        }
//            Logger.main.info("Clear device logs")
//            controller = nil
//            clearLogs()
        
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
            let alert = UIAlertController(title: NSLocalizedString("File not found", comment: "Title for the failed-to-share-your-logs alert"),
                                          message: NSLocalizedString("We couldn't find the logs on the device.", comment: "Explanation for failing to share the log file"),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "ok action"), style: .default, handler: {[weak self] _ in
                self?.deselectRow()
            }))
            
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        let items : [Any] = [ shareURL ]
        let shareController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        present(shareController, animated: true, completion: { [weak self] in
            self?.deselectRow()
        })
    }
    
    func clearLogs() {
        Logger.main.clearLogs()
        
        let controller = UIAlertController(title: NSLocalizedString("Success!", comment: "action completed successfully"), message: NSLocalizedString("Logs have been deleted from this device.", comment: "A message displayed after clearing the logs successfully."), preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "action confirmed"), style: .default, handler: { [weak self] _ in
            self?.deselectRow()
        }))
        
        present(controller, animated: true, completion: nil)
    }
    
    func deselectRow() {
        if let indexPath = tableView.indexPathForSelectedRow {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    // MARK: - Add Issuer
    
    func showAddIssuerFlow(identificationURL: URL? = nil, nonce : String? = nil) {
        let controller = AddIssuerViewController(identificationURL: identificationURL, nonce: nonce)
        controller.delegate = self
        
        let navigation = UINavigationController(rootViewController: controller)
        
        if presentedViewController != nil {
            presentedViewController?.dismiss(animated: false) { [weak self] in
                OperationQueue.main.addOperation {
                    self?.present(navigation, animated: true) {
                        controller.autoSubmitIfPossible()
                    }
                }
            }
        } else {
            present(navigation, animated: true) {
                controller.autoSubmitIfPossible()
            }
        }
    }
    
    // MARK: - Add Credential
    
    func showAddCredentialFlow() {
        Logger.main.info("Add certificate button tapped")
        
        let addCertificateFromFile = NSLocalizedString("Import Certificate from File", comment: "Contextual action. Tapping this prompts the user to add a file from a document provider.")
        let addCertificateFromURL = NSLocalizedString("Import Certificate from URL", comment: "Contextual action. Tapping this prompts the user for a URL to pull the certificate from.")
        let cancelAction = NSLocalizedString("Cancel", comment: "Cancel action")
        
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: addCertificateFromFile, style: .default, handler: { [weak self] _ in
            Logger.main.info("User has chosen to add a certificate from file")
            
            let controller = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
            controller.delegate = self
            controller.modalPresentationStyle = .formSheet
            
            self?.present(controller, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: addCertificateFromURL, style: .default, handler: { [weak self] _ in
            Logger.main.info("User has chosen to add a certificate from URL")
            
            let certificateURLPrompt = NSLocalizedString("What's the URL of the certificate?", comment: "Certificate URL prompt for importing a certificate.")
            let importAction = NSLocalizedString("Import", comment: "Import certificate action")
            
            let urlPrompt = UIAlertController(title: nil, message: certificateURLPrompt, preferredStyle: .alert)
            urlPrompt.addTextField(configurationHandler: { (textField) in
                textField.placeholder = NSLocalizedString("URL", comment: "URL placeholder text")
            })
            
            urlPrompt.addAction(UIAlertAction(title: importAction, style: .default, handler: { (_) in
                guard let urlField = urlPrompt.textFields?.first,
                    let trimmedText = urlField.text?.trimmingCharacters(in: CharacterSet.whitespaces),
                    let url = URL(string: trimmedText) else {
                        return
                }
                Logger.main.info("User attempting to add a certificate from \(url).")
                
                _ = self?.addCertificate(from: url)
            }))
            
            urlPrompt.addAction(UIAlertAction(title: cancelAction, style: .cancel, handler: { _ in
                Logger.main.info("User cancelled adding a certificate from URL.")
            }))
            
            self?.present(urlPrompt, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: cancelAction, style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    var activityIndicator: UIActivityIndicatorView?
    
    func showActivityIndicator() {
        guard self.activityIndicator == nil else { return }
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.startAnimating()
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        activityIndicator.layer.cornerRadius = 10
        activityIndicator.backgroundColor = .gray
        activityIndicator.alpha = 0.8
        
        let center: CGPoint
        if let keyView: UIView = UIApplication.shared.keyWindow?.rootViewController?.view {
            center = keyView.convert(keyView.center, to: view)
        } else {
            center = CGPoint(x: view.center.x, y: view.center.y - 32)
        }
        activityIndicator.center = center
        
        view.addSubview(activityIndicator)
        self.activityIndicator = activityIndicator
    }
    
    func hideActivityIndicator() {
        guard let activityIndicator = activityIndicator else { return }
        activityIndicator.removeFromSuperview()
        self.activityIndicator = nil
    }
    
    // Certificate handling
    func addCertificate(from url: URL) {
        showActivityIndicator()
        defer {
            hideActivityIndicator()
        }
        guard let certificate = CertificateManager().load(certificateAt: url) else {
            Logger.main.error("Failed to load certificate from \(url)")
            
            let title = NSLocalizedString("Invalid Certificate", comment: "Title for an alert when importing an invalid certificate")
            let message = NSLocalizedString("That file doesn't appear to be a valid certificate.", comment: "Message in an alert when importing an invalid certificate")
            alertError(localizedTitle: title, localizedMessage: message)
            
            return
        }
        
        saveCertificateIfOwned(certificate: certificate)
    }
    
    func importCertificate(from data: Data?) {
        showActivityIndicator()
        defer {
            hideActivityIndicator()
        }
        guard let data = data else {
            Logger.main.error("Failed to load a certificate from file. Data is nil.")
            
            let title = NSLocalizedString("Invalid Certificate", comment: "Imported certificate didn't parse title")
            let message = NSLocalizedString("That doesn't appear to be a valid Certificate file.", comment: "Imported title didn't parse message")
            alertError(localizedTitle: title, localizedMessage: message)
            return
        }
        
        do {
            let certificate = try CertificateParser.parse(data: data)
            
            saveCertificateIfOwned(certificate: certificate)
        } catch {
            Logger.main.error("Importing failed with error: \(error)")
            
            let title = NSLocalizedString("Invalid Certificate", comment: "Imported certificate didn't parse title")
            let message = NSLocalizedString("That doesn't appear to be a valid Certificate file.", comment: "Imported title didn't parse message")
            alertError(localizedTitle: title, localizedMessage: message)
            return
        }
    }
    
    func saveCertificateIfOwned(certificate: Certificate) {
        let manager = CertificateManager()
        manager.save(certificate: certificate)
    }
    
    func alertError(localizedTitle: String, localizedMessage: String) {
        let okay = NSLocalizedString("OK", comment: "OK dismiss action")
        
        let prompt = UIAlertController(title: localizedTitle, message: localizedMessage, preferredStyle: .alert);
        prompt.addAction(UIAlertAction(title: okay, style: .cancel, handler: nil))
        
        present(prompt, animated: true, completion: nil)
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
