//
//  CertificateVerificationViewController.swift
//  certificates
//
//  Created by Michael Shin on 9/11/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import UIKit

class CertificateVerificationViewController: UIViewController {

    @IBOutlet weak var bannerView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localizations.Verification
        let cancelBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "CancelIcon"), landscapeImagePhone: #imageLiteral(resourceName: "CancelIcon"), style: .done, target: self, action: #selector(closeVerification))
        navigationItem.rightBarButtonItem = cancelBarButton
    }
    
    @objc func closeVerification(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
