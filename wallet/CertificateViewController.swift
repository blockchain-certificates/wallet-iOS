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
        
        // Remove "Info" button in xib and replace it with information disclosure button
        _ = self.toolbar.items?.popLast()
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(infoTapped(_:)), for: .touchUpInside)
        let infoBarButton = UIBarButtonItem(customView: infoButton)
        self.toolbar.items?.append(infoBarButton)
        
        // Disabling key view elements for now
        infoButton.isEnabled = false
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
        let fakeContent = #imageLiteral(resourceName: "certificate")
        let shareController = UIActivityViewController(activityItems: [fakeContent], applicationActivities: nil)
        present(shareController, animated: true, completion: nil)
    }
    
    @IBAction func verifyTapped(_ sender: UIBarButtonItem) {
        let validationRequest = CertificateValidationRequest(
            for: certificate,
            bitcoinManager: bitcoinManager,
            jsonld: JSONLD.shared) { [weak self] (success, error) in
            print("Validation complete. Success? \(success). Error? \(error)")
            self?.inProgressRequest = nil
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
