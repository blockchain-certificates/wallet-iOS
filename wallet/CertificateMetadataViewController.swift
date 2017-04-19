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
private let MissingInformationCellReuseIdentifier = "MissingInformationTableViewCell"
private let InformationCellReuseIdentifier = "InformationTableViewCell"
private let DeleteCellReuseIdentifier = "DeleteTableViewCell"

class InformationTableViewCell : UITableViewCell {
    public let titleLabel: UILabel
    public let valueLabel: UILabel
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        titleLabel = UILabel()
        valueLabel = UILabel()
        
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        titleLabel.textColor = .secondaryTextColor
        titleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        valueLabel.textColor = .primaryTextColor
        valueLabel.font = UIFont.preferredFont(forTextStyle: .body)
        valueLabel.numberOfLines = 2
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        
        let views = [
            "titleLabel": titleLabel,
            "valueLabel": valueLabel
        ]
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[titleLabel][valueLabel]-|", options: .alignAllLeading, metrics: nil, views: views)
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-[titleLabel]-|", options: .alignAllLeading, metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-[valueLabel]-|", options: .alignAllLeading, metrics: nil, views: views))
        
        NSLayoutConstraint.activate(constraints)
        
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
        textLabel?.text = NSLocalizedString("Delete Certificate", comment: "Action to delete a certificate in the metadata view.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }
}

class MissingInformationTableViewCell : UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        textLabel?.text = NSLocalizedString("No additional information", comment: "Informational message about this certificate not having any metadata.")
        textLabel?.textColor = .disabledTextColor
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        tableView.backgroundColor = .baseColor

        tableView.register(InformationTableViewCell.self, forCellReuseIdentifier: InformationCellReuseIdentifier)
        tableView.register(DeleteTableViewCell.self, forCellReuseIdentifier: DeleteCellReuseIdentifier)
        tableView.register(MissingInformationTableViewCell.self, forCellReuseIdentifier: MissingInformationCellReuseIdentifier)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        
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
        self.navigationController?.navigationBar.tintColor = .brandColor
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
            if certificate.metadata.visibleMetadata.isEmpty {
                // We'll still have a cell explaining why there's no metadata
                return 1
            }
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
            return NSLocalizedString("Information", comment: "Title for the metadata view, showing additional information on a certificate")
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Choose which cell to use
        var identifier = InformationCellReuseIdentifier
        if (indexPath.section == Section.deleteCertificate.rawValue) {
            identifier = DeleteCellReuseIdentifier
        } else if (indexPath.section == Section.information.rawValue && certificate.metadata.visibleMetadata.isEmpty) {
            identifier = MissingInformationCellReuseIdentifier
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)!
        
        // Load it up with data
        switch indexPath.section {
        case Section.information.rawValue:
            if !certificate.metadata.visibleMetadata.isEmpty {
                let metadatum = certificate.metadata.visibleMetadata[indexPath.row]
                if let infoCell = cell as? InformationTableViewCell {
                    infoCell.titleLabel.text = metadatum.label
                    infoCell.valueLabel.text = metadatum.value
                }
                cell.selectionStyle = .none
            }
        case Section.deleteCertificate.rawValue:
            break
        default:
            // TODO: Is there a better way of failing here?
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
