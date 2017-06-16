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

    func dismissSettings() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isDebugBuild {
            return 3
        }
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 1
        } else if isDebugBuild && section == 2 {
            return 3
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        cell.accessoryType = .disclosureIndicator
        
        var text : String?
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            text = NSLocalizedString("Reveal Passphrase", comment: "Action item in settings screen.")
        case (1, 0):
            text = NSLocalizedString("Privacy Policy", comment: "Menu item in the settings screen that links to our privacy policy.")
        case (2, 0):
            text = "Destroy passphrase & crash"
        case (2, 1):
            text = "Delete all issuers & certificates"
        case (2, 2):
            text = "Destroy all data & crash"
        default:
            text = nil
        }
        
        cell.textLabel?.text = text
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isDebugBuild && section == 2 {
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
            controller = RevealPassphraseTableViewController()
        case (1, 0):
            controller = PrivacyViewController()
        case (2, 0):
            configuration = AppConfiguration(shouldDeletePassphrase: true, shouldResetAfterConfiguring: true)
        case (2, 1):
            configuration = AppConfiguration(shouldDeleteIssuersAndCertificates: true)
            tableView.deselectRow(at: indexPath, animated: true)
            break;
        case (2, 2):
            configuration = AppConfiguration.resetEverything
            break;
        default:
            controller = nil
        }
        
        if let newAppConfig = configuration {
            ConfigurationManager().configure(with: newAppConfig)
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
            print("Could not clear temp folder: \(error)")
        }
        NSKeyedArchiver.archiveRootObject([], toFile: Paths.issuersArchiveURL.path)
    }
}
