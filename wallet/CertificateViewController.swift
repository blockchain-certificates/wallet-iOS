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
    public let certificate: Certificate
    private let bitcoinManager = CoreBitcoinManager()
    @IBOutlet weak var renderedCertificateView: RenderedCertificateView!
    
    @IBOutlet weak var toolbar: UIToolbar!
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
    }
    
    func renderCertificate() {
        renderedCertificateView.certificateIcon.image = UIImage(data:certificate.image)
        renderedCertificateView.nameLabel.text = "\(certificate.recipient.givenName) \(certificate.recipient.familyName)"
        renderedCertificateView.titleLabel.text = certificate.title
        renderedCertificateView.subtitleLabel.text = certificate.subtitle
        renderedCertificateView.descriptionLabel.text = certificate.description
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
                }
        }
        validationRequest?.start()
        self.inProgressRequest = validationRequest
    }
    
    func infoTapped(_ button: UIButton) {
        print("\(#function)")
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
