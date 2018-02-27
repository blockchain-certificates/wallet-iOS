//
//  IssuerCollectionViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/11/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts

private let reuseIdentifier = "IssuerCollectionViewCell"
private let addIssuerReuseIdentifier = "AddIssuerCollectionViewCell"

private let segueToViewIssuer = "ShowIssuerDetail"

public enum AutocompleteRequest {
    case none
    case addIssuer(identificationURL: URL, nonce : String)
    case addCertificate(certificateURL : URL, silently: Bool, animated: Bool)
}
 
class IssuerCollectionViewController: UICollectionViewController {
    private let managedIssuersArchiveURL = Paths.managedIssuersListURL
    private let issuersArchiveURL = Paths.issuersNSCodingArchiveURL
    private let certificatesDirectory = Paths.certificatesDirectory
    private var shouldRedirectToCertificate : Certificate? = nil
    public var autocompleteRequest : AutocompleteRequest = .none {
        didSet {
            if Keychain.hasPassphrase() {
                processAutocompleteRequest()
            }
        }
    }

    // TODO: Should probably be AttributedIssuer, once I make up that model.
    var managedIssuers = [ManagedIssuer]()
    var certificates = [Certificate]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Blockcerts Wallet", comment: "Title of main interface")

        // Register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(redirectRequested(notification:)), name: NotificationNames.redirectToCertificate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onboardingCompleted(notification:)), name: NotificationNames.onboardingComplete, object: nil)

        // Set up the Collection View
        let cellNib = UINib(nibName: "IssuerCollectionViewCell", bundle: nil)
        collectionView?.register(cellNib, forCellWithReuseIdentifier: reuseIdentifier)
        let addNib = UINib(nibName: "AddIssuerCollectionViewCell", bundle: nil)
        collectionView?.register(addNib, forCellWithReuseIdentifier: addIssuerReuseIdentifier)
        // Add a section header "Issuers"
        collectionView?.register(UINib(nibName: "C5T2BLabelCell", bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderView")
        collectionView?.delegate = self
        collectionView?.backgroundColor = Style.Color.C2

        let layout = self.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: collectionView!.bounds.width - 40, height: 136)
        layout.sectionInset = UIEdgeInsetsMake(12, 20, 8, 20)
        layout.headerReferenceSize = CGSize(width: view.bounds.width, height: 44)

        navigationController?.navigationBar.barTintColor = Style.Color.C3
        navigationController?.navigationBar.isTranslucent = false

        
        // Load any existing issuers.
        loadIssuers(shouldReloadCollection: false)
        loadCertificates(shouldReloadCollection: false)
        reloadCollectionView()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        loadOnboardingIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        loadIssuers(shouldReloadCollection: false)
        loadCertificates(shouldReloadCollection: false)
        loadBackgroundView()
        reloadCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let certificate = shouldRedirectToCertificate {
            navigateTo(certificate: certificate)
            shouldRedirectToCertificate = nil
        }
    }

    func loadBackgroundView() {
        if managedIssuers.isEmpty {
            loadEmptyBackgroundView()
        } else {
            collectionView?.backgroundView = nil
        }
    }

    func loadEmptyBackgroundView() {
        if UserDefaults.standard.bool(forKey: UserDefaultsKey.hasReenteredPassphrase) {
            let emptyView: IssuerCollectionReturningUserEmptyView = .fromNib()
            collectionView?.backgroundView = emptyView
        } else {
            let emptyView: IssuerCollectionEmptyView = .fromNib()
            collectionView?.backgroundView = emptyView
        }
    }
    
    func loadOnboardingIfNeeded() {
        let hasPerformedBackup = OnboardingBackupMethods.hasPerformedBackup
        if !Keychain.hasPassphrase() || !hasPerformedBackup {
            let storyboard = UIStoryboard(name: "Onboarding", bundle: Bundle.main)
            let vc = storyboard.instantiateInitialViewController()! as! UINavigationController
            if Keychain.hasPassphrase() && !hasPerformedBackup {
                let welcome = storyboard.instantiateViewController(withIdentifier: "WelcomeReturningUsers")
                vc.viewControllers = [welcome]
            }
            present(vc, animated: false, completion: nil)
        }
    }

    // MARK: - Actions
    @IBAction func settingsTapped(_ sender: UIBarButtonItem) {
        Logger.main.info("Settings button tapped")
        
        let settingsTable = SettingsTableViewController()
        let controller = UINavigationController(rootViewController: settingsTable)
        present(controller, animated: true, completion: nil)
    }

    @objc func addIssuerButtonTapped() {
        Logger.main.info("Add issuer button tapped")
        
        showAddIssuerFlow()
    }

    func addButtonTapped(_ sender: UIBarButtonItem) {
        let addIssuer = NSLocalizedString("Add Issuer", comment: "Contextual action. Tapping this brings up the Add Issuer form.")
        let addCertificateFromFile = NSLocalizedString("Import Credential from File", comment: "Contextual action. Tapping this prompts the user to add a file from a document provider.")
        let addCertificateFromURL = NSLocalizedString("Import Credential from URL", comment: "Contextual action. Tapping this prompts the user for a URL to pull the certificate from.")
        let cancelAction = NSLocalizedString("Cancel", comment: "Cancel action")


        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: addIssuer, style: .default, handler: { [weak self] _ in
            self?.addIssuerButtonTapped()
        }))

        alertController.addAction(UIAlertAction(title: addCertificateFromFile, style: .default, handler: { [weak self] _ in
            let controller = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
            controller.delegate = self
            controller.modalPresentationStyle = .formSheet

            self?.present(controller, animated: true, completion: nil)
        }))

        alertController.addAction(UIAlertAction(title: addCertificateFromURL, style: .default, handler: { [weak self] _ in
            let certificateURLPrompt = NSLocalizedString("What's the URL of the credential?", comment: "Certificate URL prompt for importing a certificate.")
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
    
    // Mark: Notifications
    @objc func redirectRequested(notification: Notification) {
        guard let info = notification.userInfo as? [String: Certificate] else {
            Logger.main.warning("Redirect requested without a certificate. Ignoring.")
            return
        }
        guard let certificate = info["certificate"] else {
            Logger.main.warning("We don't have a certificate in the user info. whoops.")
            return
        }
        
        Logger.main.info("Redirecting from the Issuer Collection to a certificate: \(certificate)")
        
        shouldRedirectToCertificate = certificate
    }
    
    @objc func onboardingCompleted(notification: Notification) {
        precondition(Keychain.hasPassphrase(), "OnboardingCompleted notification shouldn't fire until they keychain has a passphrase.")
        processAutocompleteRequest()
    }
    
    func processAutocompleteRequest() {
        switch autocompleteRequest {
        case .none:
            break
        case .addIssuer(let identificationURL, let nonce):
            Logger.main.info("Processing autocomplete request to add issuer at \(identificationURL)")

            
            
            if presentedViewController != nil {
                presentedViewController?.dismiss(animated: false, completion: {
                    self.showAddIssuerFlow(identificationURL: identificationURL, nonce: nonce)
                })
            } else {
                showAddIssuerFlow(identificationURL: identificationURL, nonce: nonce)
            }
        case .addCertificate(let certificateURL, let silently, let animated):
            Logger.main.info("Processing autocomplete request to add certificate at \(certificateURL)")
            
            _ = add(certificateURL: certificateURL, silently: silently, animated: animated)
        }
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
        genericCell.layer.borderColor = Style.Color.C8.cgColor
        genericCell.layer.borderWidth = 1
        genericCell.layer.cornerRadius = Style.Measure.cornerRadius
        genericCell.layer.shadowColor = Style.Color.C13.cgColor
        genericCell.layer.shadowRadius = 4
        genericCell.layer.shadowOffset = CGSize(width: 2, height: 2)

        return genericCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderView", for: indexPath)
        return headerView
    }

    // MARK: Issuer handling
    func reloadCollectionView() {
        OperationQueue.main.addOperation {
            self.collectionView?.reloadData()
            self.loadBackgroundView()
        }
    }

    func loadIssuers(shouldReloadCollection : Bool = true) {
        managedIssuers = ManagedIssuerManager().load()

        if shouldReloadCollection {
            reloadCollectionView()
        }
    }

    func saveIssuers() {
        let list = ManagedIssuerList(managedIssuers: managedIssuers)
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(list)
            let success = FileManager.default.createFile(atPath: managedIssuersArchiveURL.path, contents: data, attributes: nil)
            if !success {
                Logger.main.warning("Something went wrong saving the managed issuers list")
            }
        } catch {
            Logger.main.error("An exception was thrown saving the managed issuers list: \(error)")
        }
    }

    func add(issuer: Issuer) {
        let managedIssuer = ManagedIssuer()
        managedIssuer.manage(issuer: issuer) { [weak self] success in
            self?.reloadCollectionView()
            self?.saveIssuers()
            Logger.main.info("Got identity from raw issuer \(String(describing: success))")
        }

        add(managedIssuer: managedIssuer)
    }

    func add(managedIssuer: ManagedIssuer) {
        managedIssuer.delegate = self

        // If we already have this issuer present, then let's remove it from the list and use the existing one to update it.
        // It's not great -- Really these should be immutable models so I could just test for equality.
        var otherIssuers = managedIssuers.filter { (existingManagedIssuer) -> Bool in
            return existingManagedIssuer.issuer?.id != managedIssuer.issuer?.id
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
        Logger.main.info("Deleting issuer named \(managedIssuer.issuer?.name ?? "unknown")")
        
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
            guard let fileName = certificate.filename else {
                Logger.main.error("Couldn't convert \(certificate.title) to character encoding.")
                continue
            }
            let fileURL = certificatesDirectory.appendingPathComponent(fileName)
            do {
                try certificate.file.write(to: fileURL)
            } catch {
                Logger.main.error("Couldn't save \(certificate.title) to \(fileURL): \(error)")
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

    func add(certificateURL: URL, silently: Bool = false, animated: Bool = true) -> Bool {
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

        guard data != nil, let certificate = try? CertificateParser.parse(data: data!) else {
            let title = NSLocalizedString("Invalid Credential", comment: "Title for an alert when importing an invalid certificate")
            let message = NSLocalizedString("That file doesn't appear to be a valid credential.", comment: "Message in an alert when importing an invalid certificate")

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Confirm action"), style: .default, handler: nil))

            present(alertController, animated: true, completion: nil)

            return false
        }

        let assertionUid = certificate.assertion.uid;
        guard !certificates.contains(where: { $0.assertion.uid == assertionUid }) else {
            if !silently {
                
                let title = NSLocalizedString("File already imported", comment: "Alert title when you re-import an existing certificate")
                let message = NSLocalizedString("You've already imported that file. Want to view it?", comment: "Longer explanation about importing an existing file.")
                let view = NSLocalizedString("View", comment: "Action prompt to view the imported certificate")
                let cancel = NSLocalizedString("Cancel", comment: "Dismiss action")
                let alert = AlertViewController.create(title: title, message: message, icon: .warning)
                
                let okayButton = SecondaryButton(frame: .zero)
                okayButton.setTitle(view, for: .normal)
                okayButton.onTouchUpInside { [weak self] in
                    alert.dismiss(animated: false, completion: nil)
                    self?.navigateTo(certificate: certificate, animated: true)
                }
                
                let cancelButton = SecondaryButton(frame: .zero)
                cancelButton.setTitle(cancel, for: .normal)
                cancelButton.onTouchUpInside {
                    alert.dismiss(animated: false, completion: nil)
                }
                alert.set(buttons: [okayButton, cancelButton])
                
                present(alert, animated: false, completion: nil)
            }
            return true
        }

        add(certificate: certificate)
        reloadCollectionView()

        if !silently {
            navigateTo(certificate: certificate, animated: animated)
        }

        return true
    }

    func navigateTo(issuer managedIssuer: ManagedIssuer, animated: Bool = true) -> IssuerViewController {
        Logger.main.info("Navigating to issuer \(managedIssuer.issuer?.name ?? "unknown") with id: \(managedIssuer.issuer?.id.absoluteString ?? "unknown")")
        
        if navigationController?.topViewController != self {
            navigationController?.popToViewController(self, animated: animated)
        }
        
        let issuerController = IssuerViewController()

        issuerController.managedIssuer = managedIssuer
        let matchingCertificates = certificates.filter { certificate in
            return managedIssuer.issuer != nil && certificate.issuer.id == managedIssuer.issuer!.id
        }
        issuerController.certificates = matchingCertificates

        self.navigationController?.pushViewController(issuerController, animated: animated)

        return issuerController
    }

    func navigateTo(certificate: Certificate, animated: Bool = true) {
        Logger.main.info("Navigating to certificate \(certificate.title)")
        
        // dismiss a modal view, if present
        presentedViewController?.dismiss(animated: false, completion: nil)
        
        guard let managedIssuer = managedIssuers.filter({ (possibleIssuer) -> Bool in
            return possibleIssuer.issuer?.id == certificate.issuer.id
        }).first else {
            return
        }

        let issuerController = navigateTo(issuer: managedIssuer, animated: animated)
        issuerController.navigateTo(certificate: certificate, animated: animated)
    }

    func showAddIssuerFlow(identificationURL: URL? = nil, nonce: String? = nil) {
        let controller = AddIssuerViewController(identificationURL: identificationURL, nonce: nonce)
        controller.delegate = self

        let navigation = UINavigationController(rootViewController: controller)
        navigation.navigationBar.isTranslucent = false
        navigation.navigationBar.backgroundColor = Style.Color.C3
        navigation.navigationBar.barTintColor = Style.Color.C3
        let closeButton = UIBarButtonItem(image: #imageLiteral(resourceName: "CancelIcon"), style: .plain, target: self, action: #selector(dismissModal))
        controller.navigationItem.rightBarButtonItem = closeButton

        if let presentedViewController = presentedViewController {
            presentedViewController.dismiss(animated: false) { [weak self] in
                OperationQueue.main.addOperation {
                    self?.present(navigation, animated: true) {
                        controller.autoSubmitIfPossible()
                    }
                }
            }
        } else {
            present(navigation, animated: true) {
                controller.autoSubmitIfPossible()
            }
        }
    }
    
    @objc func dismissModal() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
}


extension IssuerCollectionViewController { //  : UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let managedIssuer = managedIssuers[indexPath.item]

        _ = navigateTo(issuer: managedIssuer)
    }
}

extension IssuerCollectionViewController : ManagedIssuerDelegate {
    func updated(managedIssuer: ManagedIssuer) {
        OperationQueue.main.addOperation { [weak self] in
            self?.collectionView?.reloadData()
        }
    }
}




extension IssuerCollectionViewController : AddIssuerViewControllerDelegate {
    func added(managedIssuer: ManagedIssuer) {
        if managedIssuer.issuer != nil {
            self.add(managedIssuer: managedIssuer)
        } else {
            Logger.main.warning("Something weird -- delegate called with nil issuer. \(#function)")
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
            let title = NSLocalizedString("Invalid Credential", comment: "Imported certificate didn't parse title")
            let message = NSLocalizedString("That doesn't appear to be a valid credential file.", comment: "Imported title didn't parse message")

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


class IssuerCollectionEmptyView : UIView {}
class IssuerCollectionReturningUserEmptyView : UIView {}
class C5T2BLabelCell : UICollectionViewCell {}

