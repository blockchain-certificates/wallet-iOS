//
//  CertificateVerificationViewController.swift
//  certificates
//
//  Created by Michael Shin on 9/11/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts

class CertificateVerificationViewController: UIViewController, CertificateVerifierDelegate, CertificateVerificationViewDelegate {

    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var bannerLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var verificationView: CertificateVerificationView!
    @IBOutlet weak var doneButton: SecondaryButton!
    
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
        let cancelButton = UIBarButtonItem(image: #imageLiteral(resourceName: "icon_close"), style: .done, target: self, action: #selector(closeVerification))
        cancelButton.accessibilityLabel = Localizations.Close
        navigationItem.rightBarButtonItem = cancelButton
        
        verifier = CertificateVerifier(certificate: certificate.file)
        verifier.delegate = self
        
        bannerView.isHidden = true
        bannerLabel.isHidden = true
        bannerLabel.adjustsFontSizeToFitWidth = true
        doneButton.isHidden = true
        
        doneButton.titleLabel?.font = Style.Font.T2S
        doneButton.titleLabel?.textColor = Style.Color.C3
    
        verificationView.translatesAutoresizingMaskIntoConstraints = true
        verificationView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startVerification()
    }
    
    @objc func closeVerification(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneTapped(_ sender: Any) {
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
            alert.addAction(UIAlertAction(title: Localizations.Okay, style: .default, handler: nil))
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
        
        // WebView cannot just be created. It must also be added as a subview or weird behavior occurs.
        verifier.webView?.isHidden = true
        view.addSubview(verifier.webView!)
    }
    
    // MARK: - CertificateVerifierDelegate
    
    func updateStatus(message: String, status: VerificationStatus) {
        bannerView.isHidden = false
        bannerLabel.isHidden = false
        bannerLabel.text = message
        
        switch status {
        case .verifying:
            bannerLabel.textColor = Style.Color.C1
            bannerView.backgroundColor = Style.Color.C5
            
        case .success:
            doneButton.isHidden = false
            bannerLabel.textColor = Style.Color.C3
            bannerView.backgroundColor = Style.Color.C14
            
        case .failure:
            doneButton.isHidden = false
            bannerLabel.textColor = Style.Color.C9
            bannerView.backgroundColor = Style.Color.C15
        }
    }
    
    func notifySteps(steps: [VerificationStep]) {
        verificationView.setSteps(steps: steps)
    }
    
    func updateSubstepStatus(substep: VerificationSubstep) {
        verificationView.updateSubstepStatus(substep: substep)
    }
    
    // MARK: - CertificateVerificationViewDelegate
    
    func trackProgressChanged(y: CGFloat) {
        // TODO: center end of green progress bar
    }
}
