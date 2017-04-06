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
    
    fileprivate var certificateTableController : IssuerTableViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Summary section
        let summary = IssuerSummaryView(issuer: managedIssuer!)
        summary.frame = view.frame
        summary.translatesAutoresizingMaskIntoConstraints = false
        summary.preservesSuperviewLayoutMargins = true
        view.addSubview(summary)
        
        // Separator
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .borderColor
        view.addSubview(separator)
        
        certificateTableController = IssuerTableViewController()
        certificateTableController.managedIssuer = managedIssuer
        certificateTableController.certificates = certificates
        certificateTableController.delegate = self
        
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
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[summary][separator(==0.5)][table]|", options: .alignAllCenterX, metrics: nil, views: views)
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
        
        let title = NSLocalizedString("Are you sure you want to delete this issuer?", comment: "Confirm prompt for deleting an issuer.")
        let delete = NSLocalizedString("Delete", comment: "Delete issuer action")
        let cancel = NSLocalizedString("Cancel", comment: "Cancel action")
        
        let prompt = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        prompt.addAction(UIAlertAction(title: delete, style: .destructive, handler: { [weak self] _ in
            _ = self?.navigationController?.popToRootViewController(animated: true)
            if let rootController = self?.navigationController?.topViewController as? IssuerCollectionViewController {
                rootController.remove(managedIssuer: issuerToDelete)
            }
            
        }))
        prompt.addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
        
        present(prompt, animated: true, completion: nil)
    }
    
    func navigateTo(certificate: Certificate, animated: Bool = true) {
        let controller = CertificateViewController(certificate: certificate)
        controller.delegate = self

        OperationQueue.main.addOperation {
            self.navigationController?.pushViewController(controller, animated: animated)
        }
    }
}

extension IssuerViewController : IssuerTableViewControllerDelegate {
    func show(certificate: Certificate) {
        navigateTo(certificate: certificate)
    }
}

extension IssuerViewController : CertificateViewControllerDelegate {
    func delete(certificate: Certificate) {
        let possibleIndex = certificates.index(where: { (cert) -> Bool in
            return cert.assertion.uid == certificate.assertion.uid
        })
        guard let index = possibleIndex else {
            return
        }
        
        let documentsDirectory = Paths.certificatesDirectory
        let certificateFilename = certificate.assertion.uid
        let filePath = URL(fileURLWithPath: certificateFilename, relativeTo: documentsDirectory)
        
        let coordinator = NSFileCoordinator()
        var coordinationError : NSError?
        coordinator.coordinate(writingItemAt: filePath, options: [.forDeleting], error: &coordinationError, byAccessor: { [weak self] (file) in
            
            do {
                try FileManager.default.removeItem(at: filePath)
                if let realSelf = self {
                    realSelf.certificates.remove(at: index)
                    realSelf.certificateTableController.certificates = realSelf.certificates
                    realSelf.certificateTableController.tableView.reloadData()
                }
            } catch {
                print(error)
                let title = NSLocalizedString("Couldn't delete file", comment: "Generic error title. We couldn't delete a certificate.")
                let message = NSLocalizedString("Something went wrong when deleting that certificate.", comment: "Generic error description. We couldn't delete a certificate.")
                let okay = NSLocalizedString("OK", comment: "Confirm action")
                
                
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: okay, style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            }
        })
        
        if let error = coordinationError {
            print("Coordination failed with \(error)")
        } else {
            print("Coordination went fine.")
        }
    }
}
