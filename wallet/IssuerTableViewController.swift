//
//  IssuerTableViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/27/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts


class IssuerTableViewController: UITableViewController {

    private let issuerHeaderCellReuseIdentifier = "IssuerHeaderTableViewCell"
    private let issuerSummaryCellReuseIdentifier = "IssuerSummaryTableViewCell"
    private let certificateCellReuseIdentifier = "CertificateTitleTableViewCell"
    private let noCertificatesCellReuseIdentififer = "NoCertificateTableViewCell"

    public var delegate : IssuerTableViewControllerDelegate?
    public var managedIssuer : ManagedIssuer? {
        didSet {
            self.title = managedIssuer?.issuer?.name
        }
    }
    public var certificates : [Certificate] = []
    
    private var certificatesHeaderSeparator : UIView?
    private var estimateRequest : IssuerIssuingEstimateRequest?
    private var estimates : [CertificateIssuingEstimate]? {
        didSet {
            updateBackgroundView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "IssuerHeaderTableViewCell", bundle: nil), forCellReuseIdentifier: issuerHeaderCellReuseIdentifier)
        tableView.register(UINib(nibName: "IssuerSummaryTableViewCell", bundle: nil), forCellReuseIdentifier: issuerSummaryCellReuseIdentifier)
        tableView.register(UINib(nibName: "NoCertificatesTableViewCell", bundle: nil), forCellReuseIdentifier: noCertificatesCellReuseIdentififer)
        tableView.register(UINib(nibName: "CertificateTitleTableViewCell", bundle: nil), forCellReuseIdentifier: certificateCellReuseIdentifier)
        
        tableView.estimatedRowHeight = 87
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = .baseColor
        
        tableView.tableFooterView = UIView()
        
        tableView.separatorColor = .borderColor
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        if certificates.isEmpty {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(confirmDeleteIssuer))
            
            if let issuer = managedIssuer?.issuer as? IssuingEstimateSupport,
                let key = managedIssuer?.introducedWithAddress {
                
                estimateRequest = IssuerIssuingEstimateRequest(from: issuer, with: key) { [weak self] (result) in
                    switch result {
                    case .success(estimates: let estimates):
                        self?.estimates = estimates
                    case .errored(message: let message):
                        Logger.main.error("Issuer IssuingEstimate errored with error:\(message)")
                    case .aborted:
                        Logger.main.info("Aborted issuing estimate request")
                    }
                }
                estimateRequest?.start()
            }
        }
    }
    
    fileprivate func updateBackgroundView() {
        guard certificates.isEmpty else {
            tableView.backgroundView = nil
            return
        }
        let issuerName = managedIssuer?.issuer?.name ?? "this issuer"


        let noCertificatesTitle = NSLocalizedString("No Certificates", comment: "Title when we have no certificates for this issuer.")
        var subtitle = String(format: NSLocalizedString("You don't have any certificates from %@.", comment: "Empty certificates description when we haven't been introduced to this issuer. Format arguments: {Issuer name}"), issuerName);
        
        let hasBeenIntroduced = (managedIssuer?.introducedWithAddress != nil)
        if hasBeenIntroduced {
            if let estimates = estimates, !estimates.isEmpty {
                let sortedEstimates = estimates.sorted(by: { (leftEstimate, rightEstimate) -> Bool in
                    return leftEstimate.willIssueOn < rightEstimate.willIssueOn
                })
                let firstEstimate = sortedEstimates.first!
                
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none

                let dateString = formatter.string(from: firstEstimate.willIssueOn)
                
                subtitle = String(format: NSLocalizedString("You should see your %@ certificate from %@ around %@", comment: "Detailed estimate string for an issuer. 3 arguments: 1st is the title of the certificate, 2nd is the issuer name, 3rd is the date it will be issued on."), arguments: [firstEstimate.title, issuerName, dateString])
            } else {
                subtitle = String(format: NSLocalizedString("Hang tight! You should see an email with your certificate from %@ soon.", comment: "Empty certificates description when we've already been introduced to the issuer. Format arguments: {Issuer Name}"), issuerName)
            }
        }
        
        OperationQueue.main.addOperation { [weak self] in
            self?.tableView.backgroundView = NoContentView(title: noCertificatesTitle, subtitle: subtitle)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.isScrollEnabled = !certificates.isEmpty
        updateBackgroundView()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : certificates.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: issuerHeaderCellReuseIdentifier) as! IssuerHeaderTableViewCell
            guard let issuer = managedIssuer?.issuer else { return cell }
            cell.logoImage.image = UIImage(data: issuer.image)
            cell.nameLabel.text = issuer.name
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: certificateCellReuseIdentifier) as! CertificateTitleTableViewCell
            let certificate = certificates[indexPath.row]
            cell.title = certificate.title
            cell.subtitle = certificate.subtitle
            cell.backgroundColor = .baseColor
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else {
            return nil
        }
        let containerView = UIView()
        containerView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        containerView.backgroundColor = .baseColor
        
        let label = UILabel()
        label.text = NSLocalizedString("Certificates", comment: "Section title listing all certificates from this issuer.").uppercased()
        label.textColor = .primaryTextColor
        label.font = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .baseColor
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
        return section == 1 ? 25 : 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        let selectedCertificate = certificates[indexPath.row]
        
        Logger.main.info("Navigating to certificate \(selectedCertificate.title) with id: \(selectedCertificate.id)")
        
        delegate?.show(certificate: selectedCertificate)
    }
    
    // MARK: Key actions
    @objc func confirmDeleteIssuer() {
        guard let issuerToDelete = self.managedIssuer else {
            return
        }
        Logger.main.info("Attempting to delete issuer \(issuerToDelete.issuer?.name ?? "unknown")")
        
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
            certificatesHeaderSeparator?.backgroundColor = .baseColor
        } else {
            certificatesHeaderSeparator?.backgroundColor = .borderColor
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
        guard let filename = certificate.filename else {
            Logger.main.error("Unable to delete \(certificate.title)")
            return
        }
        
        let documentsDirectory = Paths.certificatesDirectory
        let filePath = URL(fileURLWithPath: filename, relativeTo: documentsDirectory)
        
        let coordinator = NSFileCoordinator()
        var coordinationError : NSError?
        coordinator.coordinate(writingItemAt: filePath, options: [.forDeleting], error: &coordinationError, byAccessor: { [weak self] (file) in
            do {
                try FileManager.default.removeItem(at: filePath)
                self?.certificates.remove(at: index)
                self?.tableView.reloadData()
            } catch {
                Logger.main.error("Deleting certificate \(certificate.id) failed with \(error)")
                
                let deleteTitle = NSLocalizedString("Couldn't delete file", comment: "Generic error title. We couldn't delete a certificate.")
                let deleteMessage = NSLocalizedString("Something went wrong when deleting that certificate.", comment: "Generic error description. We couldn't delete a certificate.")
                let okay = NSLocalizedString("OK", comment: "Confirm action")
                
                let alertController = UIAlertController(title: deleteTitle, message: deleteMessage, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: okay, style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            }
        })
        
        if let error = coordinationError {
            Logger.main.error("Coordination during deletion failed with \(error)")
        }
    }
}


protocol IssuerTableViewControllerDelegate : class {
    func show(certificate: Certificate);
}
