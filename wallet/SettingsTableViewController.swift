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
        title = "Settings"

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        navigationController?.navigationBar.tintColor = Colors.brandColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        oldBarStyle = navigationController?.navigationBar.barStyle
        navigationController?.navigationBar.barStyle = .default
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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)!
        
        var text : String?
        switch indexPath.row {
        case 0:
            text = "Reveal Passphrase"
        case 1:
            text = "Replace Passphrase"
        default:
            text = nil
        }
        
        cell.textLabel?.text = text
        
        return cell
    }
}
