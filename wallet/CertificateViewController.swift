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
    
    // The full amount of time that the verification alert UI remains on screen during
    // a verification process. This time is divided by the number of steps and each
    // step remains on screen at least that long
    let verificationDuration = 7.5
    
    var delegate : CertificateViewControllerDelegate?
    
    public let certificate: Certificate
    private let bitcoinManager = CoreBitcoinManager()
    
    @IBOutlet weak var renderedCertificateView: RenderedCertificateView!
    
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var verifyButton: UIButton!
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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icon_info"), style: .plain, target: self, action: #selector(displayCredentialInfo))

        shareButton.isEnabled = certificate.assertion.uid != Identifiers.sampleCertificateUID
        
        renderedCertificateView.render(certificate: certificate)
        
        analytics.track(event: .viewed, certificate: certificate)
    }
    
    // MARK: Actions
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
    
    // MARK: - Verification

    let verificationSteps = [
        NSLocalizedString("Comparing computed hash with expected hash", comment: "Verification alert title"),
        NSLocalizedString("Ensuring the Merkle receipt is valid", comment: "Verification alert title"),
        NSLocalizedString("Comparing expected Merkle root with value on the blockchain", comment: "Verification alert title"),
        NSLocalizedString("Checking if the credential has been revoked", comment: "Verification alert title"),
        NSLocalizedString("Validating issuer identity", comment: "Verification alert title"),
        NSLocalizedString("Checking expiration", comment: "Verification alert title"),
    ]
    
    // TODO: make steps 3 and 5 copy dynamic
    let validationErrors = [
        NSLocalizedString("Computed hash does not match expected hash. This credential may have been altered. Please contact the issuer.", comment: "Verification alert error description"),
        NSLocalizedString("The Merkle receipt is not valid. Please contact the issuer.", comment: "Verification alert error description"),
        NSLocalizedString("Merkle root does not match the hash value on the blockchain. Please contact the issuer.", comment: "Verification alert error description"),
        NSLocalizedString("This credential was revoked by the issuer.", comment: "Verification alert error description"),
        NSLocalizedString("Transaction occurred when the issuing address was not considered valid. Please contact the issuer.", comment: "Verification alert error description"),
        NSLocalizedString("This credential expired.", comment: "Verification alert error description"),
    ]

    /// Given the ValidationState returned from validation (if any) this will
    /// return the number of steps to show the user in the validation UI.
    /// returns nil for success, otherwise the number of the failed step.
    func validationSteps(state: String?) -> Int? {
        guard let state = state else { return nil }
        switch state {
        case "computingLocalHash", "fetchingRemoteHash", "comparingHashes":
            return 0
        case "checkingReceipt":
            return 1
        case "checkingMerkleRoot":
            return 2
        case "checkingRevokedStatus":
            return 3
        case "checkingIssuerSignature", "checkingAuthenticity":
            return 4
        case "checkingExpiresDate":
            return 5
        default:
            return 0
        }
    }
    
    func verificationTitle(step: Int) -> String {
        // TODO: localize
        return "Verifying Step \(step + 1) of \(verificationSteps.count)"
    }
    
    func successMessage() -> String {
        switch blockChain ?? .testnet {
        case .mainnet:
            return NSLocalizedString("Your credential has been successfully verified.", comment: "Detail message after mainnet validation succeeds")

        case .mocknet:
            return NSLocalizedString("This mock credential passed all checks. Mocknet mode is only used by issuers to test their workflow locally. This credential was not recorded to a blockchain and should not be considered a verified credential.", comment: "Detail message after mocknet validation succeeds")
            
        case .testnet:
            return NSLocalizedString("Your test credential has been successfully verified. This credential is for test purposes only; it has not been recorded to a blockchain.", comment: "Detail message after testnet validation succeeds")
        }
    }
    
    var verifying = false
    func animateVerification(alert: AlertViewController, currentDelay: TimeInterval, toStep: Int? = nil) {
        verifying = true
        
        let doubleDuration = verificationDuration * 1_000_000.0 / Double(verificationSteps.count)
        let stepDuration = useconds_t(Int(doubleDuration))
        let firstDelay = useconds_t(max(0, Int(stepDuration) - Int(currentDelay * 1_000_000.0)))

        DispatchQueue.global().async { [weak self] in
            if firstDelay > 0 {
                usleep(useconds_t(firstDelay))
            }
            guard let weakSelf = self, weakSelf.verifying else { return }
            var verificationStep = 0
            let stepsToShow = toStep ?? weakSelf.verificationSteps.count - 1
            while verificationStep < stepsToShow {
                verificationStep += 1
                DispatchQueue.main.async {
                    alert.set(title: weakSelf.verificationTitle(step: verificationStep))
                    alert.set(message: weakSelf.verificationSteps[verificationStep])
                }
                usleep(stepDuration)
            }
            
            // Show final result
            DispatchQueue.main.async { [weak self] in
                if let toStep = toStep {
                    // error, show specific error message
                    alert.icon = .failure
                    alert.set(title: NSLocalizedString("Failure!", comment: "Title in alert after validation fails"))
                    alert.set(message: NSLocalizedString(self?.validationErrors[toStep] ?? "", comment: "Detail message after validation failure, variable"))
                } else {
                    // successfully validated
                    alert.icon = .success
                    alert.set(title: NSLocalizedString("Verified!", comment: "Title in alert after validation succeeds"))
                    alert.set(message: self?.successMessage() ?? "")
                }
                alert.buttons.first?.setTitle("Close", for: .normal)
            }
        }
    }
    
    var progressAlert: AlertViewController?
    var verificationStartDate: Date?
    var blockChain: VerifyCredential.BlockChain?
    
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

        let progressAlert = AlertViewController.create(title: verificationTitle(step: 0), message: verificationSteps[0], icon: .verifying)
        let cancelButton = SecondaryButton(frame: .zero)
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: "Button to cancel user action"), for: .normal)
        cancelButton.onTouchUpInside { [weak self] in
            self?.verifying = false
            progressAlert.dismiss(animated: false, completion: nil)
        }
        progressAlert.set(buttons: [cancelButton])
        present(progressAlert, animated: false, completion: nil)
        self.progressAlert = progressAlert
        verificationStartDate = Date()

        let verifier = VerifyCredential(certificate: certificate.file, callback: verificationCallback)
        verifier.verify()
        blockChain = verifier.chain
    }
    
    func verificationCallback(success: Bool, steps: [String]) {
        guard let progressAlert = progressAlert else { return }
        let elapsedTime = Date().timeIntervalSince(verificationStartDate ?? Date())
        if success {
            Logger.main.info("Successfully verified certificate \(certificate.title) with id \(certificate.id)")
            animateVerification(alert: progressAlert, currentDelay: elapsedTime, toStep: nil)
        } else {
            Logger.main.info("The \(certificate.title) certificate failed verification at step \(steps.last ?? "unknown") ID: \(certificate.id)")
            animateVerification(alert: progressAlert, currentDelay: elapsedTime, toStep: validationSteps(state: steps.last))
        }
    }
    
    // MARK: - Other actions
    
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
    
    @objc func displayCredentialInfo() {
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
    func certificateValidationStateChanged(from: ValidationState, to: ValidationState) { }
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
