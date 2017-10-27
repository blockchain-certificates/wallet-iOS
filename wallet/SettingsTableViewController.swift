//
//  SettingsTableViewController.swift
//  wallet
//
//  Created by Chris Downie on 1/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
private let cellReuseIdentifier = "UITableViewCell"

private let isDebugBuild = false

class SettingsTableViewController: UITableViewController {
    private var oldBarStyle : UIBarStyle?

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
    
    // Mark: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        title = NSLocalizedString("Settings", comment: "Title of the Settings screen.")

        navigationController?.navigationBar.barTintColor = .brandColor
        
        let cancelBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "CancelIcon"), landscapeImagePhone: #imageLiteral(resourceName: "CancelIcon"), style: .done, target: self, action: #selector(dismissSettings))
        navigationItem.leftBarButtonItem = cancelBarButton
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.backgroundColor = .baseColor
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
        if isDebugBuild {
            return 4
        }
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 1
        } else if section == 2 {
            return 2
        } else if isDebugBuild && section == 3 {
            return 3
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        
        if indexPath.section < 2 {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = .none
        }
        
        var text : String?
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            text = NSLocalizedString("Reveal Passphrase", comment: "Action item in settings screen.")
        case (1, 0):
            text = NSLocalizedString("Privacy Policy", comment: "Menu item in the settings screen that links to our privacy policy.")
        case (2, 0):
            text = NSLocalizedString("Share Device Logs", comment: "Menu action item for sharing device logs.")
        case (2, 1):
            text = NSLocalizedString("Clear Device Logs", comment: "Menu item for clearing the device logs")
        case (3, 0):
            text = "Destroy passphrase & crash"
        case (3, 1):
            text = "Delete all issuers & certificates"
        case (3, 2):
            text = "Destroy all data & crash"
        default:
            text = nil
        }
        
        cell.textLabel?.text = text
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2 {
            return NSLocalizedString("Device Logs", comment: "title for the action section in settings about logs.")
        }
        if isDebugBuild && section == 3 {
            return "Debug Actions"
        }
        return nil
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var controller : UIViewController?
        var configuration : AppConfiguration?
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            Logger.main.info("Reveal passphrase tapped")
            controller = RevealPassphraseTableViewController()
        case (1, 0):
            Logger.main.info("Privacy statement tapped")
            controller = PrivacyViewController()
        case (2, 0):
            Logger.main.info("Sharing device logs")
            controller = nil
            shareLogs()
        case (2, 1):
            Logger.main.info("Clearing device logs")
            controller = nil
            clearLogs()
        case (3, 0):
            Logger.main.info("Destroying passphrase & crashing...")
            configuration = AppConfiguration(shouldDeletePassphrase: true, shouldResetAfterConfiguring: true)
        case (3, 1):
            Logger.main.info("Deleting all issuers & certificates...")
            configuration = AppConfiguration(shouldDeleteIssuersAndCertificates: true)
            tableView.deselectRow(at: indexPath, animated: true)
            break;
        case (3, 2):
            Logger.main.info("Deleting all data & crashing...")
            configuration = AppConfiguration.resetEverything
            break;
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
}
