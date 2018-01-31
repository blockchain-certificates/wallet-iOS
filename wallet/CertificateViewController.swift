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
    var delegate : CertificateViewControllerDelegate?
    
    public let certificate: Certificate
    private let bitcoinManager = CoreBitcoinManager()
    
    @IBOutlet weak var renderedCertificateView: RenderedCertificateView!
    
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var verifyButton: UIBarButtonItem!
    @IBOutlet weak var progressView: UIProgressView!
    private var inProgressRequest : CommonRequest?
    
    private let analytics = Analytics()
    
    
    init(certificate: Certificate) {
        self.certificate = certificate

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = certificate.title
        
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(moreInfoTapped), for: .touchUpInside)
        _ = toolbar.items?.popLast()
        toolbar.items?.append(UIBarButtonItem(customView: infoButton))
        
        
        shareButton.isEnabled = (certificate.assertion.uid != Identifiers.sampleCertificateUID)
        
        renderedCertificateView.render(certificate: certificate)
        stylize()
        
        analytics.track(event: .viewed, certificate: certificate)
    }
    
    func stylize() {
        toolbar.tintColor = .tintColor
        progressView.tintColor = .tintColor
    }
    
    // MARK: Actions
    @IBAction func shareTapped(_ sender: UIBarButtonItem) {
        Logger.main.info("Showing share certificate dialog for \(certificate.id)")
        // TODO: Guard against sample cert
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let shareFileAction = UIAlertAction(title: NSLocalizedString("Share File", comment: "Action to share certificate file, presented in an action sheet."), style: .default) { [weak self] _ in
            Logger.main.info("User chose to share certificate via file")
            self?.shareCertificateFile()
        }
        let shareURLAction = UIAlertAction(title: NSLocalizedString("Share Link", comment: "Action to share the certificate's hosting URL, presented in an action sheet."), style: .default) { [weak self] _ in
            Logger.main.info("User chose to share the certificate via URL.")
            self?.shareCertificateURL()
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel the action sheet."), style: .cancel, handler: { _ in
            Logger.main.info("Share dialog cancelled.")
        })
        
        if certificate.shareUrl != nil {
            alertController.addAction(shareURLAction)
        }
        alertController.addAction(shareFileAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func verifyTapped(_ sender: UIBarButtonItem) {
        Logger.main.info("User tapped verify on this certificate.")
        analytics.track(event: .validated, certificate: certificate)
        
        // Check for the Sample Certificate
        guard certificate.assertion.uid != Identifiers.sampleCertificateUID else {
            Logger.main.info("User was trying to verify the sample certificate, so we showed them our usual dialog.")
            let alert = UIAlertController(
                title: NSLocalizedString("Sample Certificate", comment: "Title for our specific warning about validating a sample certificate"),
                message: NSLocalizedString("This is a sample certificate that cannot be verified. Real certificates will perform a live validation process.", comment: "Explanation for why you can't validate the sample certificate."),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Confirm action"), style: .default, handler: nil))
            
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        verifyButton.isEnabled = false
        verifyButton.title = NSLocalizedString("Verifying...", comment: "Verifying a certificate is currently in progress")
        progressView.progress = 0.5
        progressView.isHidden = false
        
        let validationRequest = CertificateValidationRequest(
            for: certificate,
            bitcoinManager: bitcoinManager,
            jsonld: JSONLD.shared) { [weak self] (success, error) in
                let title : String
                let message : String
                if success {
                    Logger.main.info("Successfully verified certificate \(self?.certificate.title ?? "unknown") with id \(self?.certificate.id ?? "unknown")")
                    title = NSLocalizedString("Success", comment: "Title for a successful certificate validation")
                    message = NSLocalizedString("This is a valid certificate!", comment: "Message for a successful certificate validation")
                } else {
                    Logger.main.info("The \(self?.certificate.title ?? "unknown") certificate failed verification with reason: \(error ?? "unknown"). ID: \(self?.certificate.id ?? "unknown")")
                    title = NSLocalizedString("Invalid", comment: "Title for a failed certificate validation")
                    message = NSLocalizedString(error!, comment: "Specific error message for an invalid certificate.")
                }

                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Confirm action"), style: .default, handler: nil))
                
                OperationQueue.main.addOperation {
                    self?.present(alert, animated: true, completion: nil)
                    self?.inProgressRequest = nil
                    self?.verifyButton.isEnabled = true
                    self?.verifyButton.title = NSLocalizedString("Verify", comment: "Action button. Tap this to verify a certificate.")
                    self?.progressView.progress = 1
                    self?.progressView.isHidden = true
                }
        }
        validationRequest?.delegate = self
        validationRequest?.start()
        self.inProgressRequest = validationRequest
    }
    
//    @IBAction func deleteTapped(_ sender: UIBarButtonItem) {
//        let certificateToDelete = certificate
//        let title = NSLocalizedString("Be careful", comment: "Caution title presented when attempting to delete a certificate.")
//        let message = NSLocalizedString("If you delete this certificate and don't have a backup, then you'll have to ask the issuer to send it to you again if you want to recover it. Are you sure you want to delete this certificate?", comment: "Explanation of the effects of deleting a certificate.")
//        let delete = NSLocalizedString("Delete", comment: "Confirm delete action")
//        let cancel = NSLocalizedString("Cancel", comment: "Cancel action")
//
//        let prompt = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        prompt.addAction(UIAlertAction(title: delete, style: .destructive, handler: { [weak self] (_) in
//            _ = self?.navigationController?.popViewController(animated: true)
//            self?.delegate?.delete(certificate: certificateToDelete)
//        }))
//        prompt.addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
//
//        present(prompt, animated: true, completion: nil)
//    }
    
    @objc func moreInfoTapped() {
        Logger.main.info("More info tapped on the Certificate display.")
        let controller = CertificateMetadataViewController(certificate: certificate)
        controller.delegate = self
        let navController = UINavigationController(rootViewController: controller);
        present(navController, animated: true, completion: nil)
    }
    
    // Share actions
    func shareCertificateFile() {
        // Moving the file to a temporary directory.
        let filePath = "\(NSTemporaryDirectory())/certificate.json"
        let url = URL(fileURLWithPath: filePath)
        do {
            try certificate.file.write(to: url)
        } catch {
            Logger.main.error("Couldn't share certificate. Failed to write temporary URL. \(error)")
            
            let title = NSLocalizedString("Couldn't share certificate.", comment: "Alert title when sharing a certificate fails.")
            let message = NSLocalizedString("Something went wrong preparing that file for sharing. Try again later.", comment: "Alert message when sharing a certificate fails. Generic error.")
            let okay = NSLocalizedString("OK", comment: "Confirm action")
            
            let errorAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: okay, style: .default, handler: nil))
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
        
        self.present(shareController, animated: true, completion: nil)
    }
    
    func shareCertificateURL() {
        guard let url = certificate.assertion.id else {
            return
        }
        let items : [Any] = [ url ]
        
        let shareController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        let capturedCertificate = certificate
        shareController.completionWithItemsHandler = { [weak self] (activity, completed, _, _) in
            if completed {
                Logger.main.info("User completed share via URL")
                self?.analytics.track(event: .shared, certificate: capturedCertificate)
            } else {
                Logger.main.info("User canceled sharing that certificate via URL")
            }
        }
        
        self.present(shareController, animated: true, completion: nil)
    }
}

extension CertificateViewController : CertificateValidationRequestDelegate {
    func certificateValidationStateChanged(from: ValidationState, to: ValidationState) {
        var percentage : Float? = nil
        
        switch to {
        case .notStarted:
            percentage = 0.1
        case .assertingChain:
            percentage = 0.2
        case .computingLocalHash:
            percentage = 0.3
        case .fetchingRemoteHash:
            percentage = 0.4
        case .comparingHashes:
            percentage = 0.5
        case .checkingIssuerSignature:
            percentage = 0.6
        case .checkingRevokedStatus:
            percentage = 0.7
        case .success:
            percentage = 1
        case .failure:
            percentage = 1
        case .checkingReceipt:
            percentage = 0.8
        case .checkingAuthenticity:
            percentage = 0.85
        case .checkingMerkleRoot:
            percentage = 0.9
        }
        
        if let percentage = percentage {
            OperationQueue.main.addOperation {
                UIView.animate(withDuration: 0.1) {
                    self.progressView.progress = percentage
                }
            }
        }
    }
}

protocol CertificateViewControllerDelegate : class {
    func delete(certificate: Certificate)
}

extension CertificateViewController : CertificateViewControllerDelegate {
    func delete(certificate: Certificate) {
        _ = navigationController?.popViewController(animated: true)
        delegate?.delete(certificate: certificate)
    }
}
