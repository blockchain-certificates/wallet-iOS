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
    public var delegate : IssuerTableViewControllerDelegate?
    public var managedIssuer : ManagedIssuer? {
        didSet {
            self.title = managedIssuer?.issuer?.name
        }
    }
    public var certificates : [Certificate] = []
    
    private var certificatesHeaderSeparator : UIView?
    
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
            var subtitle = String(format: NSLocalizedString("You don't have any certificates from %@.", comment: "Empty certificates description when we haven't been introduced to this issuer. Format arguments: {Issuer name}"), issuerName);
            
            if managedIssuer?.introducedWithAddress != nil {
                subtitle = String(format: NSLocalizedString("Hang tight! You should see an email with your certificate from %@ soon.", comment: "Empty certificates description when we've already been introduced to the issuer. Format arguments: {Issuer Name}"), issuerName)
            }
            let noCertificatesTitle = NSLocalizedString("No Certificates", comment: "Title when we have no certificates for this issuer.")
            tableView.backgroundView = NoContentView(title: noCertificatesTitle, subtitle: subtitle)
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
        label.text = NSLocalizedString("Certificates", comment: "Section title listing all certificates from this issuer.").uppercased()
        label.textColor = Colors.primaryTextColor
        label.font = UIFont.systemFont(ofSize: 11, weight: UIFontWeightBold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = Colors.baseColor
        certificatesHeaderSeparator = separator
        
        containerView.addSubview(label)
        containerView.addSubview(separator)
        let constraints = [
            NSLayoutConstraint(item: label, attribute: .left, relatedBy: .equal, toItem: containerView, attribute: .leftMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: label, attribute: .right, relatedBy: .equal, toItem: containerView, attribute: .rightMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .topMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: separator, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: separator, attribute: .left, relatedBy: .equal, toItem: containerView, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: separator, attribute: .right, relatedBy: .equal, toItem: containerView, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: separator, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottomMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: separator, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 0.5)
        ]
        NSLayoutConstraint.activate(constraints)
        
        return containerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == Sections.certificates.rawValue {
            return 25
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == Sections.certificates.rawValue else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        let selectedCertificate = certificates[indexPath.row]
        delegate?.show(certificate: selectedCertificate)
    }
    
    // MARK: Key actions
    func confirmDeleteIssuer() {
        guard let issuerToDelete = self.managedIssuer else {
            return
        }
        
        let deleteConfirmationTitle = NSLocalizedString("Are you sure you want to delete this issuer?", comment: "Prompt to confirm delete issuer.")
        let deleteAction = NSLocalizedString("Delete", comment: "Delete issuer action")
        let cancelAction = NSLocalizedString("Cancel", comment: "Cancel action")
        
        let prompt = UIAlertController(title: deleteConfirmationTitle, message: nil, preferredStyle: .alert)
        prompt.addAction(UIAlertAction(title: deleteAction, style: .destructive, handler: { [weak self] _ in
            _ = self?.navigationController?.popToRootViewController(animated: true)
            if let rootController = self?.navigationController?.topViewController as? IssuerCollectionViewController {
                rootController.remove(managedIssuer: issuerToDelete)
            }
            
        }))
        prompt.addAction(UIAlertAction(title: cancelAction, style: .cancel, handler: nil))
        
        present(prompt, animated: true, completion: nil)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            certificatesHeaderSeparator?.backgroundColor = Colors.baseColor
        } else {
            certificatesHeaderSeparator?.backgroundColor = Colors.borderColor
        }
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
                
                let deleteTitle = NSLocalizedString("Couldn't delete file", comment: "Generic error title. We couldn't delete a certificate.")
                let deleteMessage = NSLocalizedString("Something went wrong when deleting that certificate.", comment: "Generic error description. We couldn't delete a certificate.")
                let okay = NSLocalizedString("OK", comment: "Confirm action")
                
                let alertController = UIAlertController(title: deleteTitle, message: deleteMessage, preferredStyle: .alert)
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


protocol IssuerTableViewControllerDelegate : class {
    func show(certificate: Certificate);
}
