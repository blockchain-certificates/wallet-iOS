//
//  CertificateViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/13/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import BlockchainCertificates
import JSONLD

class CertificateViewController: UIViewController {
    var delegate : CertificateViewControllerDelegate?
    
    public let certificate: Certificate
    private let bitcoinManager = CoreBitcoinManager()
    
    @IBOutlet weak var renderedCertificateView: RenderedCertificateView!
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var verifyButton: UIBarButtonItem!
    @IBOutlet weak var progressView: UIProgressView!
    private var inProgressRequest : CommonRequest?
    
    
    init(certificate: Certificate) {
        self.certificate = certificate

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = certificate.title
        renderCertificate()
        stylize()
        
        Analytics.shared.track(event: .viewed, certificate: certificate)
    }
    
    func renderCertificate() {
        renderedCertificateView.certificateIcon.image = UIImage(data:certificate.issuer.image)
        renderedCertificateView.nameLabel.text = "\(certificate.recipient.givenName) \(certificate.recipient.familyName)"
        renderedCertificateView.titleLabel.text = certificate.title
        renderedCertificateView.subtitleLabel.text = certificate.subtitle
        renderedCertificateView.descriptionLabel.text = certificate.description
        renderedCertificateView.sealIcon.image = UIImage(data: certificate.image)
        
        certificate.assertion.signatureImages.forEach { (signatureImage) in
            guard let image = UIImage(data: signatureImage.image) else {
                return
            }
            renderedCertificateView.addSignature(image: image, title: signatureImage.title)
        }
    }
    
    func stylize() {
        toolbar.tintColor = Colors.brandColor
        progressView.tintColor = Colors.brandColor
    }
    
    // MARK: Actions
    @IBAction func shareTapped(_ sender: UIBarButtonItem) {
        // Moving the file to a temporary directory. Sharing a file URL seems to be better than sharing the file's contents directly.
        let filePath = "\(NSTemporaryDirectory())/certificate.json"
        let url = URL(fileURLWithPath: filePath)
        do {
            try certificate.file.write(to: url)
        } catch {
            print("Failed to write temporary URL")
            
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
        shareController.completionWithItemsHandler = { (activity, completed, _, _) in
            if completed {
                Analytics.shared.track(event: .shared, certificate: capturedCertificate)
            }
        }
        
        self.present(shareController, animated: true, completion: nil)
    }
    
    @IBAction func verifyTapped(_ sender: UIBarButtonItem) {
        Analytics.shared.track(event: .validated, certificate: certificate)
        
        verifyButton.isEnabled = false
        verifyButton.title = NSLocalizedString("Verifying...", comment: "Verifying a certificate is currently in progress")
        progressView.progress = 0.5
        progressView.isHidden = false
        
        let validationRequest = CertificateValidationRequest(
            for: certificate,
            bitcoinManager: bitcoinManager,
            jsonld: JSONLD.shared) { [weak self] (success, error) in
                let title : String!
                let message : String!
                if success {
                    title = NSLocalizedString("Success", comment: "Title for a successful certificate validation")
                    message = NSLocalizedString("This is a valid certificate!", comment: "Message for a successful certificate validation")
                } else {
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
    
    @IBAction func deleteTapped(_ sender: UIBarButtonItem) {
        let certificateToDelete = certificate
        let title = NSLocalizedString("Be careful", comment: "Caution title presented when attempting to delete a certificate.")
        let message = NSLocalizedString("If you delete this certificate and don't have a backup, then you'll have to ask the issuer to send it to you again if you want to recover it. Are you sure you want to delete this certificate?", comment: "Explanation of the effects of deleting a certificate.")
        let delete = NSLocalizedString("Delete", comment: "Confirm delete action")
        let cancel = NSLocalizedString("Cancel", comment: "Cancel action")
        
        let prompt = UIAlertController(title: title, message: message, preferredStyle: .alert)
        prompt.addAction(UIAlertAction(title: delete, style: .destructive, handler: { [weak self] (_) in
            _ = self?.navigationController?.popViewController(animated: true)
            self?.delegate?.delete(certificate: certificateToDelete)
        }))
        prompt.addAction(UIAlertAction(title: cancel, style: .cancel, handler: nil))
        
        present(prompt, animated: true, completion: nil)
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
        case .checkingMerkleRoot:
            percentage = 0.9
        }
        
        if percentage != nil {
            UIView.animate(withDuration: 0.1, animations: { 
                self.progressView.progress = percentage!
            })
        }
    }
}

protocol CertificateViewControllerDelegate : class {
    func delete(certificate: Certificate)
}
