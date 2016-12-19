//
//  IssuerTableViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/27/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import BlockchainCertificates

private let issuerSummaryCellReuseIdentifier = "IssuerSummaryTableViewCell"
private let certificateCellReuseIdentifier = "CertificateTitleTableViewCell"
private let noCertificatesCellReuseIdentififer = "NoCertificateTableViewCell"

fileprivate enum Sections : Int {
    case certificates
    case count
}

class IssuerTableViewController: UITableViewController {
    public var managedIssuer : ManagedIssuer? {
        didSet {
            self.title = managedIssuer?.issuer?.name
        }
    }
    public var certificates : [Certificate] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "IssuerSummaryTableViewCell", bundle: nil), forCellReuseIdentifier: issuerSummaryCellReuseIdentifier)
        tableView.register(UINib(nibName: "NoCertificatesTableViewCell", bundle: nil), forCellReuseIdentifier: noCertificatesCellReuseIdentififer)
        tableView.register(UINib(nibName: "CertificateTitleTableViewCell", bundle: nil), forCellReuseIdentifier: certificateCellReuseIdentifier)
        
        tableView.estimatedRowHeight = 87
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = Colors.baseColor
        
        tableView.tableFooterView = UIView()
        
        tableView.separatorColor = Colors.borderColor
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        if certificates.isEmpty {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(confirmDeleteIssuer))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.isScrollEnabled = !certificates.isEmpty
        let issuerName = managedIssuer?.issuer?.name ?? "this issuer"
        
        if certificates.isEmpty {
            var subtitle = "You don't have any certificates from \(issuerName)."
            
            if managedIssuer?.introducedWithAddress != nil {
                subtitle = "Hang tight! You should see an email with your certificate from \(issuerName) soon."
            }
            tableView.backgroundView = NoContentView(title: "No Certificates", subtitle: subtitle)
        } else {
            tableView.backgroundView = nil
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return certificates.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: certificateCellReuseIdentifier) as! CertificateTitleTableViewCell
        let certificate = certificates[indexPath.row]
        cell.title = certificate.title
        cell.subtitle = certificate.subtitle
        cell.backgroundColor = Colors.baseColor
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == Sections.certificates.rawValue else {
            return nil
        }
        let containerView = UIView()
        containerView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        containerView.backgroundColor = Colors.baseColor
        
        let label = UILabel()
        label.text = "CERTIFICATES"
        label.textColor = Colors.primaryTextColor
        label.font = UIFont.systemFont(ofSize: 11, weight: UIFontWeightBold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(label)
        let constraints = [
            NSLayoutConstraint(item: label, attribute: .left, relatedBy: .equal, toItem: containerView, attribute: .leftMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: label, attribute: .right, relatedBy: .equal, toItem: containerView, attribute: .rightMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .topMargin, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottomMargin, multiplier: 1, constant: 8),
        ]
        NSLayoutConstraint.activate(constraints)
        
        return containerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == Sections.certificates.rawValue {
            return 40
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == Sections.certificates.rawValue else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        let selectedCertificate = certificates[indexPath.row]
        let controller = CertificateViewController(certificate: selectedCertificate)
        controller.delegate = self
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: Key actions
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

extension IssuerTableViewController : CertificateViewControllerDelegate {
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
                self?.certificates.remove(at: index)
                self?.tableView.reloadData()
            } catch {
                print(error)
                
                let alertController = UIAlertController(title: "Couldn't delete file", message: "Something went wrong deleting that certificate.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
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
