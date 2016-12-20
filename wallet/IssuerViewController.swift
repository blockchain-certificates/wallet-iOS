//
//  IssuerViewController.swift
//  wallet
//
//  Created by Chris Downie on 12/19/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import BlockchainCertificates

class IssuerViewController: UIViewController {
    var managedIssuer: ManagedIssuer? {
        didSet {
            self.title = managedIssuer?.issuer?.name
        }
    }
    var certificates = [Certificate]()
    
    private var certificateTableController : IssuerTableViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        // Summary section
        let summary = IssuerSummaryView(issuer: managedIssuer!)
        summary.frame = view.frame
        summary.translatesAutoresizingMaskIntoConstraints = false
        summary.preservesSuperviewLayoutMargins = true
        view.addSubview(summary)
        
        // Separator
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = Colors.borderColor
        view.addSubview(separator)
        
        certificateTableController = IssuerTableViewController()
        certificateTableController.managedIssuer = managedIssuer
        certificateTableController.certificates = certificates
        
        certificateTableController.willMove(toParentViewController: self)
        
        self.addChildViewController(certificateTableController)
        certificateTableController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(certificateTableController.view)
        
        certificateTableController.didMove(toParentViewController: self)
        
        
        let views : [String : UIView] = [
            "summary": summary,
            "separator": separator,
            "table": certificateTableController.view
        ]
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[summary][separator(==1)][table]|", options: .alignAllCenterX, metrics: nil, views: views)
        let horizontalSummaryConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[summary]|", options: .alignAllCenterX, metrics: nil, views: views)
        let horizontalSeparatorConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[separator]|", options: .alignAllCenterX, metrics: nil, views: views)
        let horizontalTableConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[table]|", options: .alignAllCenterX, metrics: nil, views: views)
        
        NSLayoutConstraint.activate(verticalConstraints)
        NSLayoutConstraint.activate(horizontalSummaryConstraints)
        NSLayoutConstraint.activate(horizontalSeparatorConstraints)
        NSLayoutConstraint.activate(horizontalTableConstraints)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if certificates.isEmpty {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(confirmDeleteIssuer))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let tableView = certificateTableController.tableView,
            let selectedPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedPath, animated: true)
        }
    }
    
    func confirmDeleteIssuer() {
        guard let issuerToDelete = self.managedIssuer else {
            return
        }
        
        let prompt = UIAlertController(title: "Are you sure you want to delete this issuer?", message: nil, preferredStyle: .alert)
        prompt.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            _ = self?.navigationController?.popToRootViewController(animated: true)
            if let rootController = self?.navigationController?.topViewController as? IssuerCollectionViewController {
                rootController.remove(managedIssuer: issuerToDelete)
            }
            
        }))
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(prompt, animated: true, completion: nil)
    }
}
