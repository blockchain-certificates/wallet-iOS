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
    private let buttonCellReuseIdentifier = "ButtonTableViewCell"
    private let emptyCellReuseIdentifier = "IssuerEmptyTableViewCell"

    var delegate : IssuerTableViewControllerDelegate?
    var managedIssuer : ManagedIssuer? {
        didSet {
            self.title = managedIssuer?.issuer?.name
        }
    }
    var certificates : [Certificate] = []
    var hasCertificates : Bool { return certificates.count > 0 }
    
    var certificatesHeaderSeparator : UIView?
    private var estimateRequest : IssuerIssuingEstimateRequest?
    private var estimates : [CertificateIssuingEstimate]?
    
    let shortDateFormatter = { formatter -> (DateFormatter) in
        formatter.dateStyle = .medium
        return formatter
    }(DateFormatter())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "IssuerHeaderTableViewCell", bundle: nil), forCellReuseIdentifier: issuerHeaderCellReuseIdentifier)
        tableView.register(UINib(nibName: "IssuerSummaryTableViewCell", bundle: nil), forCellReuseIdentifier: issuerSummaryCellReuseIdentifier)
        tableView.register(UINib(nibName: "NoCertificatesTableViewCell", bundle: nil), forCellReuseIdentifier: noCertificatesCellReuseIdentififer)
        tableView.register(UINib(nibName: "CertificateTitleTableViewCell", bundle: nil), forCellReuseIdentifier: certificateCellReuseIdentifier)
        tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: buttonCellReuseIdentifier)
        tableView.register(UINib(nibName: "IssuerEmptyTableViewCell", bundle: nil), forCellReuseIdentifier: emptyCellReuseIdentifier)

        tableView.estimatedRowHeight = 187
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = Style.Color.C2
        
        tableView.tableFooterView = UIView()
        tableView.separatorColor = .clear
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? max(1, certificates.count) : 1
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: issuerHeaderCellReuseIdentifier) as! IssuerHeaderTableViewCell
            guard let issuer = managedIssuer?.issuer else { return cell }
            cell.logoImage.image = UIImage(data: issuer.image)
            cell.nameLabel.text = issuer.name
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: buttonCellReuseIdentifier) as! ButtonTableViewCell
            cell.button.setTitle(NSLocalizedString("Add a Credential", comment: "Add credential in issuer detail"), for: .normal)
            cell.button.onTouchUpInside { [weak self] in
                self?.delegate?.addCertificateTapped()
            }
            return cell
        } else {
            if hasCertificates {
                let cell = tableView.dequeueReusableCell(withIdentifier: certificateCellReuseIdentifier) as! CertificateTitleTableViewCell
                let certificate = certificates[indexPath.row]
                cell.title = certificate.title
                cell.subtitle = shortDateFormatter.string(from: certificate.assertion.issuedOn)
                return cell
            } else {
                return tableView.dequeueReusableCell(withIdentifier: emptyCellReuseIdentifier)!
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1, certificates.count > 0 else {
            return nil
        }
        let containerView = UIView()
        containerView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let credentialsCount = certificates.count == 1 ? "1 credential" : "\(certificates.count) credentials"
        
        let label = LabelC5T2B()
        label.text = "You have \(credentialsCount)"
        label.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(label)
        label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20).isActive = true
        label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8).isActive = true
        containerView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 8).isActive = true
        
        return containerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return hasCertificates && section == 1 ? 32 : 0
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return hasCertificates && indexPath.section == 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard hasCertificates, indexPath.section == 1 else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        let selectedCertificate = certificates[indexPath.row]
        Logger.main.info("Navigating to certificate \(selectedCertificate.title) with id: \(selectedCertificate.id)")
        delegate?.show(certificate: selectedCertificate)
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
                let okay = NSLocalizedString("Okay", comment: "Button copy")
                
                let alert = AlertViewController.createWarning(title: deleteTitle, message: deleteMessage, buttonText: okay)
                self?.present(alert, animated: false, completion: nil)
            }
        })
        
        if let error = coordinationError {
            Logger.main.error("Coordination during deletion failed with \(error)")
        }
    }
    
}


protocol IssuerTableViewControllerDelegate : class {
    func show(certificate: Certificate)
    func addCertificateTapped()
}
