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
    }
    
    func renderCertificate() {
        renderedCertificateView.certificateIcon.image = UIImage(data:certificate.image)
        renderedCertificateView.nameLabel.text = "\(certificate.recipient.givenName) \(certificate.recipient.familyName)"
        renderedCertificateView.titleLabel.text = certificate.title
        renderedCertificateView.subtitleLabel.text = certificate.subtitle
        renderedCertificateView.descriptionLabel.text = certificate.description
        renderedCertificateView.sealIcon.image = UIImage(data: certificate.issuer.image)
        
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
            
            let errorAlert = UIAlertController(title: "Couldn't share certificate.", message: "Something went wrong preparing that file for sharing. Try again later.", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(errorAlert, animated: true, completion: nil)
            return
        }
        
        let items : [Any] = [ url ]
        
        let shareController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        self.present(shareController, animated: true, completion: nil)
    }
    
    @IBAction func verifyTapped(_ sender: UIBarButtonItem) {
        progressView.progress = 0.5
        progressView.isHidden = false
        let validationRequest = CertificateValidationRequest(
            for: certificate,
            bitcoinManager: bitcoinManager,
            jsonld: JSONLD.shared) { [weak self] (success, error) in
                let title : String!
                let message : String!
                if success {
                    title = "Success"
                    message = "This is a valid certificate!"
                } else {
                    title = "Invalid"
                    message = "\(error!)"
                }

                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                OperationQueue.main.addOperation {
                    self?.present(alert, animated: true, completion: nil)
                    self?.inProgressRequest = nil
                    self?.progressView.progress = 1
                    self?.progressView.isHidden = true
                }
        }
//        validationRequest?.delegate = self
        validationRequest?.start()
        self.inProgressRequest = validationRequest
    }
    
    @IBAction func deleteTapped(_ sender: UIBarButtonItem) {
        let certificateToDelete = certificate
        let prompt = UIAlertController(title: "Be careful", message: "If you delete this certificate and don't have a backup, then you'll have to ask the issuer to send it to you again if you want to recover it. Are you sure you want to delete this certificate?", preferredStyle: .alert)
        prompt.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] (_) in
            _ = self?.navigationController?.popViewController(animated: true)
            self?.delegate?.delete(certificate: certificateToDelete)
        }))
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(prompt, animated: true, completion: nil)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CertificateViewController : CertificateValidationRequestDelegate {
    func certificateValidationStateChanged(from: ValidationState, to: ValidationState) {
        switch to {
        default:
            print(to)
            break;
        }
    }
}

protocol CertificateViewControllerDelegate : class {
    func delete(certificate: Certificate)
}
