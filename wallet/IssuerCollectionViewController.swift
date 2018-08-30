//
//  IssuerCollectionViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/11/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import WebKit
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
    var pendingNewManagedIssuer: ManagedIssuer?
    var certificates = [Certificate]()
    var alert: AlertViewController?
    var webViewNavigationController: UINavigationController?
    
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
        AppDelegate.instance.styleApplicationDefault()
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
        let layout = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        if managedIssuers.isEmpty {
            layout.headerReferenceSize = CGSize(width: view.bounds.width, height: 0)
        } else {
            layout.headerReferenceSize = CGSize(width: view.bounds.width, height: 44)
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
        
        Logger.main.info("Redirecting from the Issuer Collection to a certificate: \(certificate.id)")
        
        shouldRedirectToCertificate = certificate
    }
    
    @objc func onboardingCompleted(notification: Notification) {
        precondition(Keychain.hasPassphrase(), "OnboardingCompleted notification shouldn't fire until they keychain has a passphrase.")
        processAutocompleteRequest()
    }
    
    func makeViewControllerVisible(action: @escaping () -> Void) {
        if let modalVC = presentedViewController {
            modalVC.dismiss(animated: false) {
                action()
            }
        } else if navigationController?.topViewController != self {
            CATransaction.begin()
            CATransaction.setCompletionBlock(action)
            navigationController?.popToViewController(self, animated: false)
            CATransaction.commit()
        } else {
            action()
        }
    }
    
    func processAutocompleteRequest() {
        switch autocompleteRequest {
        case .none:
            break
            
        case .addIssuer(let identificationURL, let nonce):
            Logger.main.info("Processing autocomplete request to add issuer at \(identificationURL)")

            makeViewControllerVisible() {
                self.addIssuerFromUniversalLink(url: identificationURL, nonce: nonce)
            }
            
        case .addCertificate(let certificateURL, let silently, let animated):
            Logger.main.info("Processing autocomplete request to add certificate at \(certificateURL)")
            
            makeViewControllerVisible() {
                self.addCertificateFromUniversalLink(url: certificateURL, silently: silently, animated: animated)
            }
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
        DispatchQueue.main.async {
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

    func addIssuerFromUniversalLink(url: URL, nonce: String) {
        
        if !Reachability.isNetworkReachable() {
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            return
        }
        
        alert = AlertViewController.createProgress(title: NSLocalizedString("Adding Issuer", comment: "Title when adding issuer in progress"))
        present(alert!, animated: false, completion: nil)
        
        AppVersion.checkUpdateRequired { [weak self] updateRequired in
            guard !updateRequired else {
                self?.showAppUpdateError()
                return
            }
            
            self?.pendingNewManagedIssuer = ManagedIssuer()
            self?.pendingNewManagedIssuer!.delegate = self
            self?.pendingNewManagedIssuer!.add(from: url, nonce: nonce, completion: { error in
                guard error == nil else {
                    self?.showAddIssuerError()
                    return
                }
                
                self?.dismissWebView()
                self?.alert?.dismiss(animated: false, completion: nil)
                
                if let pendingNewManagedIssuer = self?.pendingNewManagedIssuer {
                    self?.add(managedIssuer: pendingNewManagedIssuer)
                }
            })
        }
    }
    
    func showAppUpdateError() {
        Logger.main.info("App needs update.")
        guard let alert = alert else { return }
        
        alert.type = .normal
        alert.set(title: NSLocalizedString("[Old Version]", comment: "Force app update dialog title"))
        alert.set(message: NSLocalizedString("[Lorem ipsum latin for go to App Store]", comment: "Force app update dialog message"))
        alert.icon = .warning
        
        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(NSLocalizedString("Okay", comment: "Button copy"), for: .normal)
        okayButton.onTouchUpInside {
            let url = URL(string: "itms://itunes.apple.com/us/app/blockcerts-wallet/id1146921514")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            alert.dismiss(animated: false, completion: nil)
        }
        
        let cancelButton = SecondaryButton(frame: .zero)
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: "Dismiss action"), for: .normal)
        cancelButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
        }
        
        alert.set(buttons: [okayButton, cancelButton])
    }
    
    func showAddIssuerError() {
        guard let alert = alert else { return }
        
        let title = NSLocalizedString("Add Issuer Failed", comment: "Alert title when adding an issuer fails for any reason.")
        let cannedMessage = NSLocalizedString("There was an error adding this issuer. This can happen when a single-use invitation link is clicked more than once. Please check with the issuer and request a new invitation, if necessary.", comment: "Error message displayed when adding issuer failed")
        
        alert.type = .normal
        alert.set(title: title)
        alert.set(message: cannedMessage)
        alert.icon = .failure
        
        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(NSLocalizedString("Okay", comment: "OK dismiss action"), for: .normal)
        okayButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
        }
        alert.set(buttons: [okayButton])
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
        self.collectionView?.reloadData()
        self.loadBackgroundView()
    }

    func remove(managedIssuer: ManagedIssuer) {
        guard let index = managedIssuers.index(of: managedIssuer) else {
            return
        }
        Logger.main.info("Deleting issuer named \(managedIssuer.issuer?.name ?? "unknown")")
        
        managedIssuers.remove(at: index)
        saveIssuers()

        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }


    // MARK: Certificate handling
    func loadCertificates(shouldReloadCollection : Bool = true) {
        certificates = []

        let existingFiles = try? FileManager.default.contentsOfDirectory(at: certificatesDirectory, includingPropertiesForKeys: nil, options: [])
        let files = existingFiles ?? []

        let loadedCertificates : [Certificate] = files.compactMap { fileURL in
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
            let managedIssuer = ManagedIssuer()
            managedIssuer.manage(issuer: certificate.issuer) { [weak self] success in
                self?.reloadCollectionView()
                self?.saveIssuers()
                Logger.main.info("Got identity from raw issuer \(String(describing: success))")
            }
            
            add(managedIssuer: managedIssuer)
        }

        certificates.append(certificate)
        saveCertificates()
    }

    func addCertificateFromUniversalLink(url: URL, silently: Bool = false, animated: Bool = true) {
        if !Reachability.isNetworkReachable() {
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            return
        }
        
        alert = AlertViewController.createProgress(title: NSLocalizedString("Adding Certificate", comment: "Title when adding certificate in progress"))
        present(alert!, animated: false, completion: nil)
        
        AppVersion.checkUpdateRequired { [weak self] updateRequired in
            guard !updateRequired else {
                self?.showAppUpdateError()
                return
            }
            
            guard let data = self?.certificateDataFromURL(url), let certificate = try? CertificateParser.parse(data: data) else {
                self?.showCertificateInvalid()
                return
            }
            
            guard let certificates = self?.certificates, !certificates.contains(where: { $0.assertion.uid == certificate.assertion.uid }) else {
                if !silently {
                    self?.showCertificateAlreadyAdded(certificate)
                }
                return
            }
            
            self?.add(certificate: certificate)
            self?.reloadCollectionView()
            
            if !silently {
                self?.navigateTo(certificate: certificate, animated: animated)
            }
        }
    }
    
    func showCertificateAlreadyAdded(_ certificate: Certificate) {
        guard let alert = alert else { return }
        
        let title = NSLocalizedString("File already imported", comment: "Alert title when you re-import an existing certificate")
        let message = NSLocalizedString("You've already imported that file. Want to view it?", comment: "Longer explanation about importing an existing file.")
        let view = NSLocalizedString("View", comment: "Action prompt to view the imported certificate")
        let cancel = NSLocalizedString("Cancel", comment: "Dismiss action")
        
        alert.type = .normal
        alert.set(title: title)
        alert.set(message: message)
        
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
        alert.set(buttons: [okayButton, cancelButton], clear: true)
        
        present(alert, animated: false, completion: nil)
    }
    
    func showCertificateInvalid() {
        guard let alert = alert else { return }
        
        let title = NSLocalizedString("Invalid Credential", comment: "Title for an alert when importing an invalid certificate")
        let message = NSLocalizedString("That file doesn't appear to be a valid credential.", comment: "Message in an alert when importing an invalid certificate")
        let okay = NSLocalizedString("Okay", comment: "Button copy")
        
        alert.type = .normal
        alert.set(title: title)
        alert.set(message: message)
        
        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(okay, for: .normal)
        okayButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
        }
        alert.set(buttons: [okayButton], clear: true)
        
        present(alert, animated: false, completion: nil)
    }

    func certificateDataFromURL(_ url: URL) -> Data? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
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
        
        return data
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
        DispatchQueue.main.async { [weak self] in
            self?.collectionView?.reloadData()
        }
    }
    
    func presentWebView(at url: URL, with navigationDelegate: WKNavigationDelegate) throws {
        Logger.main.info("Presenting the web view in the Add Issuer screen.")
        
        let webController = WebLoginViewController(requesting: url, navigationDelegate: navigationDelegate) { [weak self] in
            self?.cancelWebLogin()
            self?.dismissWebView()
        }
        let navigationController = UINavigationController(rootViewController: webController)
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.backgroundColor = Style.Color.C3
        navigationController.navigationBar.barTintColor = Style.Color.C3
        webViewNavigationController = navigationController
        
        DispatchQueue.main.async {
            self.alert?.dismiss(animated: false, completion: {
                self.present(navigationController, animated: true, completion: nil)
            })
        }
    }
    
    func dismissWebView() {
        DispatchQueue.main.async { [weak self] in
            self?.webViewNavigationController?.dismiss(animated: true, completion: nil)
        }
    }

    func cancelWebLogin() {
        pendingNewManagedIssuer?.abortRequests()
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
        guard let data = data else {
            let title = NSLocalizedString("Couldn't read file", comment: "Title for an error message displayed when we can't read a certificate file the user tried to import.")
            let message = NSLocalizedString("Something went wrong when trying to open the file.", comment: "A longer explanation of the error message displayed when we can't read a certificate file the user tried to import.")
            let okay = NSLocalizedString("Okay", comment: "Button copy")
            
            let alert = AlertViewController.createWarning(title: title, message: message, buttonText: okay)
            present(alert, animated: false, completion: nil)
            return
        }
        guard let certificate = try? CertificateParser.parse(data: data) else {
            let title = NSLocalizedString("Invalid Credential", comment: "Imported certificate didn't parse title")
            let message = NSLocalizedString("That doesn't appear to be a valid credential file.", comment: "Imported title didn't parse message")
            let okay = NSLocalizedString("Okay", comment: "Button copy")
            
            let alert = AlertViewController.createWarning(title: title, message: message, buttonText: okay)
            present(alert, animated: false, completion: nil)
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


class IssuerCollectionEmptyView : UIView {
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIScreen.main.bounds.height < 490 {
            // Handle special layout needs of app running inside an iPad
            imageHeightConstraint.constant = 120
        } else if UIScreen.main.bounds.height < 570 {
            // Handle special layout needs of app running in an iPhone 5 sized device
            imageHeightConstraint.constant = 200
        }
        setNeedsLayout()
    }
}
class IssuerCollectionReturningUserEmptyView : IssuerCollectionEmptyView {}
class C5T2BLabelCell : UICollectionViewCell {}

