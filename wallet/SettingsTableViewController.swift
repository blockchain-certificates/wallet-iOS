//
//  SettingsTableViewController.swift
//  wallet
//
//  Created by Chris Downie on 1/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
private let cellReuseIdentifier = "UITableViewCell"

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

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        navigationController?.navigationBar.tintColor = Colors.brandColor
        
        let cancelBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "CancelIcon"), landscapeImagePhone: #imageLiteral(resourceName: "CancelIcon"), style: .done, target: self, action: #selector(dismissSettings))
        navigationItem.leftBarButtonItem = cancelBarButton
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.backgroundColor = Colors.baseColor
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
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return 1
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
        case (0, 1):
            text = NSLocalizedString("Replace Passphrase", comment: "Action item in settings screen.")
        case (1, 0):
            text = NSLocalizedString("Privacy Policy", comment: "Menu item in the settings screen that links to our privacy policy.")
        default:
            text = nil
        }
        
        cell.textLabel?.text = text
        
        return cell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var controller : UIViewController?
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            controller = RevealPassphraseTableViewController()
        case (0, 1):
            controller = ReplacePassphraseViewController()
        case (1, 0):
            controller = PrivacyViewController()
        default:
            controller = nil
        }
        
        if let controller = controller {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}
