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
    private let tag = String(describing: IssuerCollectionViewController.self)
    
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
    var webViewNavigationController: NavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Logger.main.tag(tag).info("view_did_load")
        
        title = Localizations.BlockcertsWallet

        // Register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(redirectRequested(notification:)), name: NotificationNames.redirectToCertificate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onboardingCompleted(notification:)), name: NotificationNames.onboardingComplete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCertificates(notification:)), name: NotificationNames.reloadCertificates, object: nil)

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

        // Load any existing issuers.
        loadIssuers(shouldReloadCollection: false)
        loadCertificates(shouldReloadCollection: false)
        reloadCollectionView()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        loadOnboardingIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        Logger.main.tag(tag).info("view_will_appear")
        loadIssuers(shouldReloadCollection: false)
        loadCertificates(shouldReloadCollection: false)
        loadBackgroundView()
        reloadCollectionView()
        navigationController?.styleDefault()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Logger.main.tag(tag).info("view_did_appear")
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
            Logger.main.tag(tag).info("loading onboarding")
            let storyboard = UIStoryboard(name: "Onboarding", bundle: Bundle.main)
            let vc = storyboard.instantiateInitialViewController()! as! UINavigationController
            if Keychain.hasPassphrase() && !hasPerformedBackup {
                Logger.main.tag(tag).info("returning user")
                let welcome = storyboard.instantiateViewController(withIdentifier: "WelcomeReturningUsers")
                vc.viewControllers = [welcome]
            }
            present(vc, animated: false, completion: nil)
        }
    }

    // MARK: - Actions
    @IBAction func settingsTapped(_ sender: UIBarButtonItem) {
        Logger.main.tag(tag).info("Settings button tapped")
        
        let settingsTable = SettingsTableViewController()
        let controller = NavigationController(rootViewController: settingsTable)
        present(controller, animated: true, completion: nil)
    }
    
    // Mark: Notifications
    @objc func redirectRequested(notification: Notification) {
        guard let info = notification.userInfo as? [String: Certificate] else {
            Logger.main.tag(tag).warning("Redirect requested without a certificate. Ignoring.")
            return
        }
        guard let certificate = info["certificate"] else {
            Logger.main.tag(tag).warning("We don't have a certificate in the user info. whoops.")
            return
        }
        
        Logger.main.tag(tag).info("Redirecting from the Issuer Collection to a certificate: \(certificate.id)")
        
        shouldRedirectToCertificate = certificate
    }
    
    @objc func onboardingCompleted(notification: Notification) {
        precondition(Keychain.hasPassphrase(), "OnboardingCompleted notification shouldn't fire until they keychain has a passphrase.")
        processAutocompleteRequest()
    }
    
    @objc func reloadCertificates(notification: Notification) {
        loadCertificates(shouldReloadCollection: true)
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
            Logger.main.tag(tag).info("Processing autocomplete request to add issuer at \(identificationURL)")

            makeViewControllerVisible() {
                self.addIssuerFromUniversalLink(url: identificationURL, nonce: nonce)
            }
            
        case .addCertificate(let certificateURL, let silently, let animated):
            Logger.main.tag(tag).info("Processing autocomplete request to add certificate at \(certificateURL)")
            
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
            cell.issuerName = Localizations.MissingIssuer
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
        let tag = self.tag
        Logger.main.tag(tag).debug("add issuer form universal link with url: \(url) and nonce: \(nonce)")

        Logger.main.tag(tag).info("checking network")
        if !Reachability.isNetworkReachable() {
            Logger.main.tag(tag).error("network unreachable")
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            return
        }
        Logger.main.tag(tag).info("network reachable")
        
        alert = AlertViewController.createProgress(title: Localizations.AddingIssuer)
        present(alert!, animated: false, completion: nil)

        Logger.main.tag(tag).info("checking update required")
        AppVersion.checkUpdateRequired { [weak self] updateRequired in
            guard !updateRequired else {
                Logger.main.tag(self?.tag).error("app update required")
                self?.showAppUpdateError()
                return
            }
            Logger.main.tag(self?.tag).info("no update required")
            
            self?.pendingNewManagedIssuer = ManagedIssuer()
            self?.pendingNewManagedIssuer!.delegate = self
            self?.pendingNewManagedIssuer!.add(from: url, nonce: nonce, completion: { error in
                guard error == nil else {
                    Logger.main.tag(tag).error("Error adding issuer \(error)")
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
        let tag = self.tag
        Logger.main.tag(tag).info("App needs update.")
        guard let alert = alert else { return }
        
        alert.type = .normal
        alert.set(title: Localizations.AppUpdateAlertTitle)
        alert.set(message: Localizations.AppUpdateAlertMessage)
        alert.icon = .warning
        
        let okayButton = DialogButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside {
            let url = URL(string: "itms://itunes.apple.com/us/app/blockcerts-wallet/id1146921514")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            Logger.main.tag(tag).debug("tapped update_app with link: \(url)")
            alert.dismiss(animated: false, completion: nil)
        }
        
        let cancelButton = DialogButton(frame: .zero)
        cancelButton.setTitle(Localizations.Cancel, for: .normal)
        cancelButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
            Logger.main.tag(tag).warning("tapped update_dismiss")
        }
        
        alert.set(buttons: [cancelButton, okayButton])
    }
    
    func showAddIssuerError() {
        let tag = self.tag
        Logger.main.tag(tag).info("showing add_issuer_error_dismiss")
        guard let alert = alert else { return }
        
        alert.type = .normal
        alert.set(title: Localizations.AddIssuerFailAlertTitle)
        alert.set(message: Localizations.AddIssuerFailMessage)
        alert.icon = .failure
        
        let okayButton = DialogButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside {
            Logger.main.tag(tag).info("tapped add_issuer_error_dismiss")
            alert.dismiss(animated: false, completion: nil)
        }
        alert.set(buttons: [okayButton])
    }

    func saveIssuers() {
        Logger.main.tag(tag).info("saving issuer")
        let list = ManagedIssuerList(managedIssuers: managedIssuers)
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(list)
            let success = FileManager.default.createFile(atPath: managedIssuersArchiveURL.path, contents: data, attributes: nil)
            if !success {
                Logger.main.tag(tag).warning("Something went wrong saving the managed issuers list at path: \(managedIssuersArchiveURL.path)")
            }
        } catch {
            Logger.main.tag(tag).error("An exception was thrown saving the managed issuers list: \(error)")
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
        Logger.main.tag(tag).info("loading certificates")
        certificates = []

        let existingFiles = try? FileManager.default.contentsOfDirectory(at: certificatesDirectory, includingPropertiesForKeys: nil, options: [])
        let files = existingFiles ?? []

        Logger.main.tag(tag).debug("existing file certificates: \(existingFiles)")
        let loadedCertificates : [Certificate] = files.compactMap { fileURL in
            guard let data = try? Data(contentsOf: fileURL) else {
                Logger.main.tag(tag).error("nil data")
                return nil
            }
            Logger.main.tag(tag).info("trying to parse certificate")
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
        Logger.main.tag(tag).info("saving certificates")
        // Make sure the `certificatesDirectory` exists by trying to create it every time.
        try? FileManager.default.createDirectory(at: certificatesDirectory, withIntermediateDirectories: false, attributes: nil)

        for certificate in certificates {
            guard let fileName = certificate.filename else {
                Logger.main.tag(tag).error("Couldn't convert \(certificate.title) to character encoding.")
                continue
            }
            let fileURL = certificatesDirectory.appendingPathComponent(fileName)
            do {
                try certificate.file.write(to: fileURL)
            } catch {
                Logger.main.tag(tag).error("Couldn't save \(certificate.title) to \(fileURL): \(error)")
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
                Logger.main.tag(self?.tag).info("Got identity from raw issuer \(String(describing: success))")
            }
            
            add(managedIssuer: managedIssuer)
        }

        certificates.append(certificate)
        saveCertificates()
    }

    func addCertificateFromUniversalLink(url: URL, silently: Bool = false, animated: Bool = true) {
        Logger.main.debug("add certificate from universal link: \(url)")
        if !Reachability.isNetworkReachable() {
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            return
        }
        
        alert = AlertViewController.createProgress(title: Localizations.AddingCredential)
        present(alert!, animated: false, completion: nil)

        Logger.main.tag(tag).info("checking update required")
        AppVersion.checkUpdateRequired { [weak self] updateRequired in
            guard !updateRequired else {
                Logger.main.tag(self?.tag).error("app update required")
                self?.showAppUpdateError()
                return
            }
            Logger.main.tag(self?.tag).info("no update required")
            
            guard let data = self?.certificateDataFromURL(url), let certificate = try? CertificateParser.parse(data: data) else {
                Logger.main.tag(self?.tag).error("certificate invalid with url: \(url)")
                self?.showCertificateInvalid()
                return
            }
            
            guard let certificates = self?.certificates, !certificates.contains(where: { $0.assertion.uid == certificate.assertion.uid }) else {
                Logger.main.tag(self?.tag).error("certificate with url: \(url) already added")
                if !silently {
                    self?.alert?.dismiss(animated: false, completion: {
                        self?.showCertificateAlreadyAdded(certificate)
                    })
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
        let alert = AlertViewController.createWarning(title: Localizations.FileAlreadyImported, message: Localizations.FileAlreadyImportedExplanation)

        alert.type = .normal

        if (alert.buttons.count > 0) {
            alert.buttons[0].removeFromSuperview()
        }

        let okayButton = DialogButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside { [weak self] in
            alert.dismiss(animated: false, completion: nil)
            self?.navigateTo(certificate: certificate, animated: true)
        }
        
        let cancelButton = DialogButton(frame: .zero)
        cancelButton.setTitle(Localizations.Cancel, for: .normal)
        cancelButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
        }
        alert.set(buttons: [okayButton, cancelButton], clear: true)

        present(alert, animated: false, completion: nil)
    }
    
    func showCertificateInvalid() {
        guard let alert = alert else { return }
        
        alert.type = .normal
        alert.set(title: Localizations.InvalidCredential)
        alert.set(message: Localizations.InvalidCredentialFile)
        
        let okayButton = SecondaryButton(frame: .zero)
        okayButton.setTitle(Localizations.Okay, for: .normal)
        okayButton.onTouchUpInside {
            alert.dismiss(animated: false, completion: nil)
        }
        alert.set(buttons: [okayButton], clear: true)
        
        present(alert, animated: false, completion: nil)
    }

    func certificateDataFromURL(_ url: URL) -> Data? {
        Logger.main.tag(tag).debug("certificate data from url: \(url)")
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
        Logger.main.tag(tag).info("Navigating to issuer \(managedIssuer.issuer?.name ?? "unknown") with id: \(managedIssuer.issuer?.id.absoluteString ?? "unknown")")
        
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
        Logger.main.tag(tag).info("Navigating to certificate \(certificate.title)")
        
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
        
        DispatchQueue.main.async { [weak self] in
            let webController = WebLoginViewController(requesting: url, navigationDelegate: navigationDelegate) { [weak self] in
                self?.cancelWebLogin()
                self?.dismissWebView()
            }
            let navigationController = NavigationController(rootViewController: webController)
            self?.webViewNavigationController = navigationController
            
            self?.alert?.dismiss(animated: false, completion: { [weak self] in
                self?.present(navigationController, animated: true, completion: nil)
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
        Logger.main.tag(tag).info("import certificate")
        guard let data = data else {
            let alert = AlertViewController.createWarning(title: Localizations.ReadFileError,
                                                          message: Localizations.CredentialParseError,
                                                          buttonText: Localizations.Okay)
            present(alert, animated: false, completion: nil)
            Logger.main.tag(tag).info("credential parse error data was nil")
            return
        }
        guard let certificate = try? CertificateParser.parse(data: data) else {
            let alert = AlertViewController.createWarning(title: Localizations.InvalidCredential,
                                                          message: Localizations.InvalidCredentialFile,
                                                          buttonText: Localizations.Okay)
            present(alert, animated: false, completion: nil)
            Logger.main.tag(tag).info("invalid credential file while parsing data")
            return
        }

        // At this point, data is totally a valid certificate. Let's save that to the documents directory.
        add(certificate: certificate)
    }
}

extension IssuerCollectionViewController : UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        Logger.main.tag(tag).info("document picker at: \(url)")
        let data = try? Data(contentsOf: url)

        importCertificate(from: data)
    }
}


class IssuerCollectionEmptyView : UIView {}
class IssuerCollectionReturningUserEmptyView : IssuerCollectionEmptyView {}
class C5T2BLabelCell : UICollectionViewCell {}

