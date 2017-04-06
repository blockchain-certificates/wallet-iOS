//
//  CertificateMetadataViewController.swift
//  wallet
//
//  Created by Chris Downie on 4/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import BlockchainCertificates

enum Section : Int {
    case information = 0, deleteCertificate
    case count
}

// Mark: - Custom UITableViewCells
private let InformationCellReuseIdentifier = "InformationTableViewCell"
private let DeleteCellReuseIdentifier = "DeleteTableViewCell"

class InformationTableViewCell : UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        textLabel?.textColor = Colors.secondaryTextColor
        textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        
        detailTextLabel?.textColor = Colors.primaryTextColor
        detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DeleteTableViewCell : UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier);
        
        textLabel?.textAlignment = .center
        textLabel?.textColor = .red
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }
}

class CertificateMetadataViewController: UIViewController {
    public var delegate : CertificateViewControllerDelegate?
    fileprivate let certificate : Certificate
    private var tableView : UITableView!

    init(certificate: Certificate) {
        self.certificate = certificate
        tableView = nil
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView()
        
        let tableView : UITableView = UITableView(frame: .zero, style: .grouped);
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(InformationTableViewCell.self, forCellReuseIdentifier: InformationCellReuseIdentifier)
        tableView.register(DeleteTableViewCell.self, forCellReuseIdentifier: DeleteCellReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints);
        
        self.tableView = tableView
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = certificate.title
        
        let dismissButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissSelf))
        self.navigationController?.navigationBar.tintColor = Colors.brandColor
        navigationItem.leftBarButtonItem = dismissButton
    }

    func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    func promptForCertificateDeletion() {
        let certificateToDelete = certificate
        let title = NSLocalizedString("Be careful", comment: "Caution title presented when attempting to delete a certificate.")
        let message = NSLocalizedString("If you delete this certificate and don't have a backup, then you'll have to ask the issuer to send it to you again if you want to recover it. Are you sure you want to delete this certificate?", comment: "Explanation of the effects of deleting a certificate.")
        let delete = NSLocalizedString("Delete", comment: "Confirm delete action")
        let cancel = NSLocalizedString("Cancel", comment: "Cancel action")
        
        let prompt = UIAlertController(title: title, message: message, preferredStyle: .alert)
        prompt.addAction(UIAlertAction(title: delete, style: .destructive, handler: { [weak self] (_) in
            self?.delegate?.delete(certificate: certificateToDelete)
            self?.dismissSelf();
        }))
        prompt.addAction(UIAlertAction(title: cancel, style: .cancel, handler: { [weak self] (_) in
            if let selectedPath = self?.tableView.indexPathForSelectedRow {
                self?.tableView.deselectRow(at: selectedPath, animated: true)
            }
        }))
        
        present(prompt, animated: true, completion: nil)
    }
    
}

extension CertificateMetadataViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count.rawValue
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue:section) {
        case .some(.information):
            return certificate.metadata.visibleMetadata.count
        case .some(.deleteCertificate):
            return 1
        case .none:
            fallthrough
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Section.information.rawValue {
            return "Information"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var identifier = InformationCellReuseIdentifier
        if (indexPath.section == Section.deleteCertificate.rawValue) {
            identifier = DeleteCellReuseIdentifier
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)!
        
        switch indexPath.section {
        case Section.information.rawValue:
            let metadatum = certificate.metadata.visibleMetadata[indexPath.row]
            cell.textLabel?.text = metadatum.label
            cell.detailTextLabel?.text = metadatum.value
            cell.selectionStyle = .none
        case Section.deleteCertificate.rawValue:
            cell.textLabel?.text = "Delete Certificate"
        default:
            cell.textLabel?.text = ""
        }
        
        return cell;
    }
    
}

extension CertificateMetadataViewController : UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }

        switch section {
        case .deleteCertificate:
            promptForCertificateDeletion();
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
