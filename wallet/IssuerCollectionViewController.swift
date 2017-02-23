 //
//  IssuerCollectionViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/11/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import BlockchainCertificates

private let reuseIdentifier = "IssuerCollectionViewCell"
private let addIssuerReuseIdentifier = "AddIssuerCollectionViewCell"

private let segueToViewIssuer = "ShowIssuerDetail"

class IssuerCollectionViewController: UICollectionViewController {
    private let issuersArchiveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Issuers")
    private let certificatesDirectory = Paths.certificatesDirectory
    
    // TODO: Should probably be AttributedIssuer, once I make up that model.
    var managedIssuers = [ManagedIssuer]()
    var certificates = [Certificate]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the Collection View
        let cellNib = UINib(nibName: "IssuerCollectionViewCell", bundle: nil)
        self.collectionView?.register(cellNib, forCellWithReuseIdentifier: reuseIdentifier)
        let addNib = UINib(nibName: "AddIssuerCollectionViewCell", bundle: nil)
        self.collectionView?.register(addNib, forCellWithReuseIdentifier: addIssuerReuseIdentifier)
        self.collectionView?.delegate = self
        self.collectionView?.backgroundColor = Colors.baseColor
        
        adjustCellSize()

        // Style this bad boy
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = Colors.brandColor
        self.navigationController?.navigationBar.tintColor = Colors.tintColor
        navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: Colors.tintColor
        ]
        navigationController?.navigationBar.barStyle = .blackOpaque
        
        // Load any existing issuers.
        loadIssuers(shouldReloadCollection: false)
        loadCertificates(shouldReloadCollection: false)
        reloadCollectionView()
        title = NSLocalizedString("Issuers", comment: "Title in screen of multiple issuers")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadCertificates()
        loadBackgroundView()
    }
    
    func loadBackgroundView() {
        if managedIssuers.isEmpty {
            loadEmptyBackgroundView()
        } else {
            loadBrandedBackgroundView()
        }
    }
    
    func loadEmptyBackgroundView() {
        guard collectionView?.backgroundView == nil else {
            // We know the backgroundView is either this emptyState or nil. So this saves us from re-loading the same background view if it's already loaded.
            return
        }
        let title = NSLocalizedString("No Issuers", comment: "Empty issuers title")
        let subtitle = NSLocalizedString("Add your first Issuer by tapping the add button above.", comment: "Instructions below the empty issuers title, explaining how to add your first issuer.")
        let emptyView = NoContentView(title: title, subtitle: subtitle)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            NSLayoutConstraint(item: emptyView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: emptyView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: emptyView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: emptyView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ]
        
        let backgroundView = UIView()
        backgroundView.addSubview(emptyView)

        collectionView?.backgroundView = backgroundView
        NSLayoutConstraint.activate(constraints)
    }
    
    func loadBrandedBackgroundView() {
        collectionView?.backgroundView = nil
    }
    
    func adjustCellSize() {
        // Constants
        let spacing : CGFloat = 8
        let textHeight : CGFloat = 35
        
        guard let deviceWidth = self.collectionView?.bounds.width,
            let deviceHeight = self.collectionView?.bounds.height else {
            return
        }
        let targetWidth = min(deviceWidth, deviceHeight)

        // figure out best size.
        let newWidth = (targetWidth - (3 * spacing)) / 2
        let newHeight = newWidth + textHeight
        
        let layout = self.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: newWidth, height: newHeight)
    }
    
    // MARK: - Actions
    @IBAction func settingsTapped(_ sender: UIBarButtonItem) {
        let settingsTable = SettingsTableViewController()
        let controller = UINavigationController(rootViewController: settingsTable)
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        let addIssuer = NSLocalizedString("Add Issuer", comment: "Contextual action. Tapping this brings up the Add Issuer form.")
        let addCertificateFromFile = NSLocalizedString("Import Certificate from File", comment: "Contextual action. Tapping this prompts the user to add a file from a document provider.")
        let addCertificateFromURL = NSLocalizedString("Import Certificate from URL", comment: "Contextual action. Tapping this prompts the user for a URL to pull the certificate from.")
        let cancelAction = NSLocalizedString("Cancel", comment: "Cancel action")
        
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: addIssuer, style: .default, handler: { [weak self] _ in
            self?.showAddIssuerFlow()
        }))
        
        alertController.addAction(UIAlertAction(title: addCertificateFromFile, style: .default, handler: { [weak self] _ in
            let controller = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
            controller.delegate = self
            controller.modalPresentationStyle = .formSheet
            
            self?.present(controller, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: addCertificateFromURL, style: .default, handler: { [weak self] _ in
            let certificateURLPrompt = NSLocalizedString("What's the URL of the certificate?", comment: "Certificate URL prompt for importing a certificate.")
            let importAction = NSLocalizedString("Import", comment: "Import certificate action")
            
            let urlPrompt = UIAlertController(title: nil, message: certificateURLPrompt, preferredStyle: .alert)
            urlPrompt.addTextField(configurationHandler: { (textField) in
                textField.placeholder = NSLocalizedString("URL", comment: "URL placeholder text")
            })
            
            urlPrompt.addAction(UIAlertAction(title: importAction, style: .default, handler: { (_) in
                guard let urlField = urlPrompt.textFields?.first,
                    let trimmedText = urlField.text?.trimmingCharacters(in: CharacterSet.whitespaces),
                    let url = URL(string: trimmedText) else {
                        return
                }
                
                _ = self?.add(certificateURL: url)
            }))
            
            urlPrompt.addAction(UIAlertAction(title: cancelAction, style: .cancel, handler: nil))
            
            self?.present(urlPrompt, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: cancelAction, style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return managedIssuers.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let genericCell : UICollectionViewCell!

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! IssuerCollectionViewCell
        
        let managedIssuer = managedIssuers[indexPath.item]
        guard let issuer = managedIssuer.issuer else {
            cell.issuerName = NSLocalizedString("Missing Issuer", comment: "Error state: missing issuer data in issuer cell")
            return cell
        }
        
        cell.imageView.image = UIImage(data: issuer.image)
        cell.issuerName = issuer.name
        cell.certificateCount = certificates.reduce(0, { (count, certificate) -> Int in
            if certificate.issuer.id == issuer.id {
                return count + 1
            }
            return count
        })
        
        genericCell = cell
        
        // Common styling
        genericCell.layer.borderColor = Colors.borderColor.cgColor
        genericCell.layer.borderWidth = 0.5
        genericCell.layer.cornerRadius = 3
        
        return genericCell
    }
    
    // MARK: Issuer handling
    func reloadCollectionView() {
        OperationQueue.main.addOperation {
            self.collectionView?.reloadData()
            self.loadBackgroundView()
        }
    }
    
    func loadIssuers(shouldReloadCollection : Bool = true) {
        managedIssuers = NSKeyedUnarchiver.unarchiveObject(withFile: issuersArchiveURL.path) as? [ManagedIssuer] ?? []
        
        if shouldReloadCollection {
            reloadCollectionView()
        }
    }
    
    func saveIssuers() {
        NSKeyedArchiver.archiveRootObject(managedIssuers, toFile: issuersArchiveURL.path)
    }
    
    func add(issuer: Issuer) {
        let managedIssuer = ManagedIssuer()
        managedIssuer.manage(issuer: issuer) { [weak self] success in
            self?.reloadCollectionView()
            self?.saveIssuers()
            print("Got identity from raw issuer \(success)")
        }
        
        add(managedIssuer: managedIssuer)
    }
    
    func add(managedIssuer: ManagedIssuer) {
        // If we already have this issuer present, then let's remove it from the list and use the existing one to update it.
        // It's not great -- Really these should be immutable models so I could just test for equality.
        var otherIssuers = managedIssuers.filter { (existingManagedIssuer) -> Bool in
            return existingManagedIssuer.issuer != managedIssuer.issuer
        }
        otherIssuers.append(managedIssuer)
        managedIssuers = otherIssuers
        
        saveIssuers()
        OperationQueue.main.addOperation {
            self.collectionView?.reloadData()
        }
    }
    
    func remove(managedIssuer: ManagedIssuer) {
        guard let index = managedIssuers.index(of: managedIssuer) else {
            return
        }
        
        managedIssuers.remove(at: index)
        saveIssuers()
        
        OperationQueue.main.addOperation {
            self.collectionView?.reloadData()
        }
    }
    

    // MARK: Certificate handling
    func loadCertificates(shouldReloadCollection : Bool = true) {
        certificates = []
        
        let existingFiles = try? FileManager.default.contentsOfDirectory(at: certificatesDirectory, includingPropertiesForKeys: nil, options: [])
        let files = existingFiles ?? []
        
        let loadedCertificates : [Certificate] = files.flatMap { fileURL in
            guard let data = try? Data(contentsOf: fileURL) else {
                return nil
            }
            return try? CertificateParser.parse(data: data)
        }
        
        loadedCertificates.forEach { certificate in
            self.add(certificate: certificate)
        }
        
        if shouldReloadCollection {
            reloadCollectionView()
        }
    }
    
    func saveCertificates() {
        // Make sure the `certificatesDirectory` exists by trying to create it every time.
        try? FileManager.default.createDirectory(at: certificatesDirectory, withIntermediateDirectories: false, attributes: nil)
        
        for certificate in certificates {
            let fileURL = certificatesDirectory.appendingPathComponent(certificate.assertion.uid)
            do {
                try certificate.file.write(to: fileURL)
            } catch {
                print("ERROR: Couldn't save \(certificate.title) to \(fileURL): \(error)")
                dump(certificate)
                // TODO: Remove this fatalError call. It's really just in here during development.
                fatalError()
            }
        }
    }
    
    func add(certificate: Certificate) {
        let isKnownIssuer = managedIssuers.contains(where: { (existingManager) -> Bool in
            return existingManager.issuer?.id == certificate.issuer.id
        })
        
        if !isKnownIssuer {
            add(issuer: certificate.issuer)
        }
        
        certificates.append(certificate)
        saveCertificates()
    }
    
    func add(certificateURL: URL) -> Bool {
        var components = URLComponents(url: certificateURL, resolvingAgainstBaseURL: false)
        let formatQueryItem = URLQueryItem(name: "format", value: "json")
        
        if components?.queryItems == nil {
            components?.queryItems = [
                formatQueryItem
            ]
        } else {
            components?.queryItems?.append(formatQueryItem)
        }
        
        var data: Data? = nil
        if let dataURL = components?.url {
            data = try? Data(contentsOf: dataURL)
        }
        
        if let data = data,
            let certificate = try? CertificateParser.parse(data: data) {
            add(certificate: certificate)
            reloadCollectionView()
            return true
        } else {
            // TODO: Show some alert saying that this URL isn't a valid certifiate url.
        }
        
        return false
    }
    
    func showAddIssuerFlow(identificationURL: URL? = nil, nonce : String? = nil) {
        let controller = AddIssuerViewController(identificationURL: identificationURL, nonce: nonce)
        controller.delegate = self
        
        let navigation = UINavigationController(rootViewController: controller)
        
        present(navigation, animated: true) {
            controller.autoSubmitIfPossible()
        }
    }
}


extension IssuerCollectionViewController { //  : UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let managedIssuer = managedIssuers[indexPath.item]
        let issuerController = IssuerViewController()
        
        issuerController.managedIssuer = managedIssuer
        issuerController.certificates = certificates.filter { certificate in
            return managedIssuer.issuer != nil && certificate.issuer.id == managedIssuer.issuer!.id
        }
        
        self.navigationController?.pushViewController(issuerController, animated: true)
    }
}

extension IssuerCollectionViewController : AddIssuerViewControllerDelegate {
    func added(managedIssuer: ManagedIssuer) {
        if managedIssuer.issuer != nil {
            self.add(managedIssuer: managedIssuer)
        } else {
            print("Something weird -- delegate called with nil issuer. \(#function)")
        }
    }
}

// MARK: Functions from the open source.
extension IssuerCollectionViewController {
    func importCertificate(from data: Data?) {
        let okay = NSLocalizedString("OK", comment: "OK dismiss action")
        guard let data = data else {
            let title = NSLocalizedString("Couldn't read file", comment: "Title for an error message displayed when we can't read a certificate file the user tried to import.")
            let message = NSLocalizedString("Something went wrong when trying to open the file.", comment: "A longer explanation of the error message displayed when we can't read a certificate file the user tried to import.")
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: okay, style: .default, handler: { [weak alertController] action in
                alertController?.dismiss(animated: true, completion: nil)
                }))
            present(alertController, animated: true, completion: nil)
            return
        }
        guard let certificate = try? CertificateParser.parse(data: data) else {
            let title = NSLocalizedString("Invalid Certificate", comment: "Imported certificate didn't parse title")
            let message = NSLocalizedString("That doesn't appear to be a valid Certificate file.", comment: "Imported title didn't parse message")
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: okay, style: .default, handler: { [weak alertController] action in
                alertController?.dismiss(animated: true, completion: nil)
                }))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        // At this point, data is totally a valid certificate. Let's save that to the documents directory.
        add(certificate: certificate)
    }
}

extension IssuerCollectionViewController : UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let data = try? Data(contentsOf: url)
        
        importCertificate(from: data)
    }
}
