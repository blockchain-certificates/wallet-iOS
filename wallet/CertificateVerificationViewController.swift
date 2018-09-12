//
//  CertificateVerificationViewController.swift
//  certificates
//
//  Created by Michael Shin on 9/11/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts

class CertificateVerificationViewController: UIViewController, CertificateVerifierDelegate {

    @IBOutlet weak var bannerView: UILabel!
    
    let certificate: Certificate
    var verifier: CertificateVerifier!
    var progressAlert: AlertViewController?
    
    init(certificate: Certificate) {
        self.certificate = certificate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localizations.Verification
        let cancelBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "CancelIcon"), landscapeImagePhone: #imageLiteral(resourceName: "CancelIcon"), style: .done, target: self, action: #selector(closeVerification))
        navigationItem.rightBarButtonItem = cancelBarButton
        
        verifier = CertificateVerifier(certificate: certificate.file)
        verifier.delegate = self
        
        bannerView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startVerification()
    }
    
    @objc func closeVerification(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func startVerification() {
        // Check for the Sample Certificate
        guard certificate.assertion.uid != Identifiers.sampleCertificateUID else {
            Logger.main.info("User was trying to verify the sample certificate, so we showed them our usual dialog.")
            
            let alert = UIAlertController(
                title: Localizations.SampleCredential,
                message: Localizations.SampleCredentialVerificationImpossible,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: Localizations.OK, style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        // Check for connectivity
        if !Reachability.isNetworkReachable() {
            let alert = AlertViewController.createNetworkWarning()
            present(alert, animated: false, completion: nil)
            return
        }
        
        verifier.verify()
    }
    
    // MARK: - CertificateVerifierDelegate
    
    func updateStatus(message: String, status: VerificationStatus) {
        bannerView.isHidden = false
        bannerView.text = message
        
        switch status {
        case .verifying:
            bannerView.textColor = Style.Color.C1
            bannerView.backgroundColor = Style.Color.C5
            
        case .success:
            bannerView.textColor = Style.Color.C3
            bannerView.backgroundColor = Style.Color.C14
            
        case .failure:
            bannerView.textColor = Style.Color.C9
            bannerView.backgroundColor = Style.Color.C15
        }
    }
    
    func notifySteps(steps: [ParentStep]) {
        //
    }
    
    func updateSubstepStatus(substep: Step) {
        //
    }
}
