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

class CertificateViewController: UIViewController, CertificateVerifierDelegate {
    
    var delegate : CertificateViewControllerDelegate?
    
    public let certificate: Certificate
    private let bitcoinManager = CoreBitcoinManager()
    
    @IBOutlet weak var renderedCertificateView: RenderedCertificateView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var verifyButton: UIButton!
    
    private var inProgressRequest : CommonRequest?
    private let analytics = Analytics()
    var progressAlert: AlertViewController?
    var verifier: CertificateVerifier!
    
    init(certificate: Certificate) {
        self.certificate = certificate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icon_info"), style: .plain, target: self, action: #selector(displayCertificateInfo))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        verifier = CertificateVerifier(certificate: certificate.file)
        verifier.delegate = self
        
        shareButton.isEnabled = certificate.assertion.uid != Identifiers.sampleCertificateUID
        renderedCertificateView.render(certificate: certificate)
        analytics.track(event: .viewed, certificate: certificate)
    }
    
    // MARK: - Verification
    
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

        // Check for connectivity
        if !Reachability.isNetworkReachable() {
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            return
        }
        
        progressAlert = AlertViewController.createProgress(title: "[Initializing]")
        let cancelButton = SecondaryButton(frame: .zero)
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: "Button to cancel user action"), for: .normal)
        cancelButton.onTouchUpInside { [weak self] in
            self?.verifier.cancel()
            self?.progressAlert!.dismiss(animated: false, completion: nil)
        }
        progressAlert!.set(verificationButtons: [cancelButton])
        present(progressAlert!, animated: false, completion: nil)

        verifier.verify()
    }
    
    // MARK: - CertificateVerifierDelegate
    
    func start(blockChain: BlockChain) {
        progressAlert?.set(title: "Verifying Ethereum")
    }
    
    func startSubstep(stepLabel: String, substepLabel: String) {
        progressAlert?.type = .verification
        progressAlert?.set(header: "Verifying Ethereum")
        progressAlert?.set(title: stepLabel)
        progressAlert?.set(message: substepLabel)
    }
    
    func finishSubstep(success: Bool, errorMessage: String?) {
        //
    }
    
    func finish(success: Bool, errorMessage: String?) {
        progressAlert?.type = .normal
        let cancelButton = SecondaryButton(frame: .zero)
        cancelButton.setTitle(NSLocalizedString("Close", comment: "Button to cancel user action"), for: .normal)
        cancelButton.onTouchUpInside { [weak self] in
            self?.verifier.cancel()
            self?.progressAlert!.dismiss(animated: false, completion: nil)
        }
        progressAlert!.set(buttons: [cancelButton])
        
        if success {
            progressAlert?.icon = .success
            progressAlert?.set(title: "Verified!")
            progressAlert?.set(message: "Your credential has been successfully verified.")
        } else {
            progressAlert?.icon = .failure
            progressAlert?.set(title: "Verification Fail")
            progressAlert?.set(message: errorMessage!)
        }
    }
    
    // MARK: - More Info
    
    @objc func displayCertificateInfo() {
        Logger.main.info("More info tapped on the Certificate display.")
        
        let controller = CertificateMetadataViewController(certificate: certificate)
        controller.delegate = self
        let navController = UINavigationController(rootViewController: controller);
        present(navController, animated: true, completion: nil)
    }
    
    // MARK: - Share
    
    @IBAction func shareTapped(_ sender: UIBarButtonItem) {
        Logger.main.info("Showing share certificate dialog for \(certificate.id)")
        
        // TODO: Guard against sample cert
        let alertController = UIAlertController(title: nil, message: "Share this credential", preferredStyle: .actionSheet)
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
