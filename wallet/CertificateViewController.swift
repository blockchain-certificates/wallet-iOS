//
//  CertificateViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/13/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts
import JSONLD

class CertificateViewController: UIViewController {
    
    @IBOutlet weak var renderedCertificateView: RenderedCertificateView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var footerView: UIView!
    
    let certificate: Certificate
    let analytics = Analytics()
    var delegate : CertificateViewControllerDelegate?
    
    init(certificate: Certificate) {
        self.certificate = certificate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localizations.Credential
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        shareButton.isEnabled = certificate.assertion.uid != Identifiers.sampleCertificateUID
        renderedCertificateView.render(certificate: certificate)
        analytics.track(event: .viewed, certificate: certificate)
        
        footerView.layer.borderColor = Style.Color.C8.cgColor;
        footerView.layer.borderWidth = 1;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.styleAlternate()
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        navigationController?.styleDefault()
    }
    
    @IBAction func verifyTapped(_ sender: UIButton) {
        Logger.main.info("User tapped verify on this certificate.")
        analytics.track(event: .validated, certificate: certificate)
        
        let verificationController = CertificateVerificationViewController(certificate: certificate)
        let navController = NavigationController(rootViewController: verificationController)
        navController.styleDefault()
        present(navController, animated: true, completion: nil)
    }
    
    // MARK: - More Info
    
    @IBAction func infoTapped(_ sender: UIButton) {
        Logger.main.info("More info tapped on the Certificate display.")
        
        let controller = CertificateMetadataViewController(certificate: certificate)
        controller.delegate = self
        let navController = UINavigationController(rootViewController: controller);
        navController.styleDefault()
        present(navController, animated: true, completion: nil)
    }
    
    // MARK: - Share
    
    @IBAction func shareTapped(_ sender: UIButton) {
        Logger.main.info("Showing share certificate dialog for \(certificate.id)")
        
        // TODO: Guard against sample cert
        let alertController = UIAlertController(title: Localizations.ShareCredential, message: nil, preferredStyle: .actionSheet)
        let shareFileAction = UIAlertAction(title: Localizations.ShareFile, style: .default) { [weak self] _ in
            Logger.main.info("User chose to share certificate via file")
            self?.shareCertificateFile()
        }
        let shareURLAction = UIAlertAction(title: Localizations.ShareLink, style: .default) { [weak self] _ in
            Logger.main.info("User chose to share the certificate via URL.")
            self?.shareCertificateURL()
        }
        let cancelAction = UIAlertAction(title: Localizations.Cancel, style: .cancel, handler: { _ in
            Logger.main.info("Share dialog cancelled.")
        })
        
        if certificate.shareUrl != nil {
            alertController.addAction(shareURLAction)
        }
        alertController.addAction(shareFileAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func shareCertificateFile() {
        // Moving the file to a temporary directory.
        let filePath = "\(NSTemporaryDirectory())/certificate.json"
        let url = URL(fileURLWithPath: filePath)
        do {
            try certificate.file.write(to: url)
        } catch {
            Logger.main.error("Couldn't share certificate. Failed to write temporary URL. \(error)")
            
            let errorAlert = UIAlertController(title: Localizations.ShareCredentialError, message: Localizations.ShareCredentialGenericError, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: Localizations.OK, style: .default, handler: nil))
            present(errorAlert, animated: true, completion: nil)
            return
        }
        
        let items : [Any] = [ url ]
        let shareController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        let capturedCertificate = certificate
        
        shareController.completionWithItemsHandler = { [weak self] (activity, completed, _, _) in
            if completed {
                Logger.main.info("User completed share via file.")
                self?.analytics.track(event: .shared, certificate: capturedCertificate)
            } else {
                Logger.main.info("User canceled sharing that certificate via file.")
            }
        }
        present(shareController, animated: true, completion: nil)
    }
    
    func shareCertificateURL() {
        guard let url = certificate.assertion.id else {
            return
        }
        
        let items : [Any] = [ url ]
        let capturedCertificate = certificate
        let shareController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        shareController.completionWithItemsHandler = { [weak self] (activity, completed, _, _) in
            if completed {
                Logger.main.info("User completed share via URL")
                self?.analytics.track(event: .shared, certificate: capturedCertificate)
            } else {
                Logger.main.info("User canceled sharing that certificate via URL")
            }
        }
        present(shareController, animated: true, completion: nil)
    }
}

extension CertificateViewController : CertificateValidationRequestDelegate {
    func certificateValidationStateChanged(from: ValidationState, to: ValidationState) { }
}

protocol CertificateViewControllerDelegate : class {
    func delete(certificate: Certificate)
}

extension CertificateViewController : CertificateViewControllerDelegate {
    func delete(certificate: Certificate) {
        delegate?.delete(certificate: certificate)
    }
}
