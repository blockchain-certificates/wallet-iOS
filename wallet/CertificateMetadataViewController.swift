//
//  CertificateMetadataViewController.swift
//  wallet
//
//  Created by Chris Downie on 4/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts

// MARK: - Table Cell View Model

protocol TableCellModel {
    static var cellClass: AnyClass { get }
    static var reuseIdentifier: String { get }
    var reuseIdentifier: String { get }
    func decorate(_ cell: UITableViewCell)
}

extension TableCellModel {
    var reuseIdentifier: String {
        return type(of: self).reuseIdentifier
    }
}

struct InfoCell : TableCellModel {
    static let cellClass: AnyClass = InformationTableViewCell.self
    static let reuseIdentifier = "InformationTableViewCell"
    
    let title: String
    let detail: String
    let url: URL?
    
    func decorate(_ cell: UITableViewCell) {
        guard let cell = cell as? InformationTableViewCell else { return }
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = detail
        cell.isTappable = url != nil
        cell.selectionStyle = cell.isTappable ? .default : .none
    }
}

struct DeleteCell : TableCellModel {
    static let cellClass: AnyClass = DeleteTableViewCell.self
    static let reuseIdentifier = "DeleteTableViewCell"
    
    func decorate(_ cell: UITableViewCell) {
        cell.selectionStyle = .none
    }
}


// Mark: - Custom UITableViewCells
private let InformationCellReuseIdentifier = "InformationTableViewCell"
private let DeleteCellReuseIdentifier = "DeleteTableViewCell"

class InformationTableViewCell : UITableViewCell {
    
    var isTappable = false
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        guard let textLabel = textLabel, let detailTextLabel = detailTextLabel else {
            return
        }

        contentView.translatesAutoresizingMaskIntoConstraints = false

        textLabel.font = Style.Font.T2B
        textLabel.textColor = Style.Color.C5
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        detailTextLabel.font = Style.Font.T3R
        detailTextLabel.textColor = Style.Color.C6
        detailTextLabel.numberOfLines = 0
        detailTextLabel.lineBreakMode = .byWordWrapping
        detailTextLabel.translatesAutoresizingMaskIntoConstraints = false
        detailTextLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        textLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        trailingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 20).isActive = true
        
        detailTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        trailingAnchor.constraint(equalTo: detailTextLabel.trailingAnchor, constant: 20).isActive = true
        detailTextLabel.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 4).isActive = true
        contentView.bottomAnchor.constraint(equalTo: detailTextLabel.bottomAnchor, constant: 8).isActive = true
        
        contentView.topAnchor.constraint(equalTo: topAnchor)
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class DeleteTableViewCell : UITableViewCell {
    
    var button : UIButton
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        button = DangerButton(frame: .zero)
        button.setTitle(NSLocalizedString("Delete Credential", comment: "Action to delete a credential in the metadata view."), for: .normal)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24).isActive = true
        contentView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 24).isActive = true
        button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        contentView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 20).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



// MARK: - View Controller

class BaseMetadataViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var data = [TableCellModel]()
    
    public var delegate : CertificateViewControllerDelegate?
    private var tableView : UITableView!

    let dateFormatter = { formatter -> (DateFormatter) in
        formatter.dateStyle = .medium
        return formatter
    }(DateFormatter())

    init() {
        tableView = nil
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView()
        
        navigationController?.navigationBar.isTranslucent = false
        
        let tableView : UITableView = UITableView(frame: .zero, style: .grouped)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(InfoCell.cellClass, forCellReuseIdentifier: InfoCell.reuseIdentifier)
        tableView.register(DeleteCell.cellClass, forCellReuseIdentifier: DeleteCell.reuseIdentifier)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        self.tableView = tableView
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dismissButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissSelf))
        navigationItem.leftBarButtonItem = dismissButton
        navigationController?.navigationBar.barTintColor = Style.Color.C3

        tableView.separatorStyle = .none
        view.backgroundColor = Style.Color.C1
        tableView.backgroundColor = Style.Color.C1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let path = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: path, animated: true)
        }
    }

    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func dismissSelfAfterDeletion() {
        guard let navigationController = presentingViewController as? UINavigationController, navigationController.viewControllers.count > 1 else { return }
        
        let depth = navigationController.viewControllers.count
        let popTo = depth > 2 ? navigationController.viewControllers[1] : navigationController.viewControllers.first!
        dismiss(animated: true, completion: { navigationController.popToViewController(popTo, animated: true) })
    }

    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? data.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else { return UITableViewCell() }

        let item = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier)!
        item.decorate(cell)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let cellData = data[indexPath.row] as? InfoCell,
            let url = cellData.url,
            UIApplication.shared.canOpenURL(url) else { return false }
        return cellData.url != nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cellData = data[indexPath.row] as? InfoCell,
            let url = cellData.url,
            UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
}


class CertificateMetadataViewController: BaseMetadataViewController {

    private let certificate : Certificate

    init(certificate: Certificate) {
        self.certificate = certificate
        super.init()
        
        let issuedOn = dateFormatter.string(from: certificate.assertion.issuedOn)
        let expirationDate = certificate.issuer.publicKeys.first?.expires
        let expiresOn = expirationDate.map { dateFormatter.string(from: $0) } ?? NSLocalizedString("Never", comment: "Credential info screen description of credential that never expires")
        
        data.append(InfoCell(title: NSLocalizedString("Credential Name", comment: "Credential info screen field label"), detail: certificate.title, url: nil))
        data.append(InfoCell(title: NSLocalizedString("Date Issued", comment: "Credential info screen field label"), detail: issuedOn, url: nil))
        data.append(InfoCell(title: NSLocalizedString("Credential Expiration", comment: "Credential info screen field label"), detail: expiresOn, url: nil))
        data.append(InfoCell(title: NSLocalizedString("Description", comment: "Credential info screen field label"), detail: certificate.description, url: nil))
        
        let metadata : [TableCellModel] = certificate.metadata.visibleMetadata.map { metadata in
            let url : URL?
            switch metadata.type {
            case .uri:
                url = URL(string: metadata.value)
            case .email:
                url = URL(string: "mailto:\(metadata.value)")
            case .phoneNumber:
                url = URL(string: "tel:\(metadata.value)")
            default:
                url = nil
            }
            return InfoCell(title: metadata.label, detail: metadata.value, url: url)
        }
        data += metadata

        data.append(DeleteCell())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("Credential Info", comment: "Title of credential information screen")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let cell = cell as? DeleteTableViewCell {
            cell.button.onTouchUpInside { [weak self] in
                self?.promptForCertificateDeletion()
            }
        }
        return cell
    }

    func promptForCertificateDeletion() {
        Logger.main.info("User has tapped the delete button on this certificate.")
        let certificateToDelete = certificate
        
        let title = NSLocalizedString("Be careful", comment: "Caution title presented when attempting to delete a certificate.")
        let message = NSLocalizedString("If you delete this certificate and don't have a backup, then you'll have to ask the issuer to send it to you again if you want to recover it. Are you sure you want to delete this certificate?", comment: "Explanation of the effects of deleting a certificate.")
        let delete = NSLocalizedString("Delete", comment: "Confirm delete action")
        let cancel = NSLocalizedString("Cancel", comment: "Cancel action")

        let alert = AlertViewController.create(title: title, message: message, icon: .warning)

        let okayButton = DangerButton(frame: .zero)
        okayButton.setTitle(delete, for: .normal)
        okayButton.onTouchUpInside { [weak self] in
            Logger.main.info("User has deleted certificate \(certificateToDelete.title) with id \(certificateToDelete.id)")
            self?.delegate?.delete(certificate: certificateToDelete)
            alert.dismiss(animated: false, completion: nil)
            self?.dismissSelfAfterDeletion()
        }
        
        let cancelButton = SecondaryButton(frame: .zero)
        cancelButton.setTitle(cancel, for: .normal)
        cancelButton.onTouchUpInside {
            Logger.main.info("User canceled the deletion of the certificate.")
            alert.dismiss(animated: false, completion: nil)
        }
        alert.set(buttons: [okayButton, cancelButton])

        present(alert, animated: false, completion: nil)
    }
    
}


class IssuerMetadataViewController : BaseMetadataViewController {
    
    private let issuer : ManagedIssuer
    
    init(issuer: ManagedIssuer) {
        self.issuer = issuer
        super.init()
        
        if let name = issuer.issuer?.name {
            data.append(InfoCell(title: NSLocalizedString("Issuer Name", comment: "Issuer info screen field label"), detail: name, url: nil))
        }
        if let introducedOn = issuer.introducedOn {
            data.append(InfoCell(title: NSLocalizedString("Introduced on", comment: "Issuer info screen field label"), detail: dateFormatter.string(from: introducedOn), url: nil))
        }
        if let address = issuer.introducedWithAddress {
            data.append(InfoCell(title: NSLocalizedString("Shared Address", comment: "Issuer info screen field label"), detail: address.scopedValue, url: nil))
        }
        if let email = issuer.issuer?.email {
            data.append(InfoCell(title: NSLocalizedString("Email", comment: "Issuer info screen field label"), detail: email, url: URL(string: "mailto:\(email)")))
        }
//        data.append(InfoCell(title: NSLocalizedString("URL", comment: "Issuer info screen field label"), detail: issuer.url  // issuer.id.absoluteString, url: issuer.id))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("Issuer Info", comment: "Title of credential information screen")
    }

}

