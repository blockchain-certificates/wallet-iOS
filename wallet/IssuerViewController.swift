//
//  IssuerViewController.swift
//  wallet
//
//  Created by Chris Downie on 12/19/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import BlockchainCertificates

class IssuerViewController: UIViewController {
    var managedIssuer: ManagedIssuer?
    var certificates = [Certificate]()
    
    private var certificateTableController : IssuerTableViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let summary = IssuerSummaryView(issuer: managedIssuer!)
        summary.frame = view.frame
        view.addSubview(summary)
//
//        // Do any additional setup after loading the view.
//        certificateTableController = IssuerTableViewController()
//        certificateTableController.managedIssuer = managedIssuer
//        certificateTableController.certificates = certificates
//        
//        certificateTableController.willMove(toParentViewController: self)
//        
//        self.addChildViewController(certificateTableController)
//        certificateTableController.view.frame = self.view.frame
//        view.addSubview(certificateTableController.view)
//        
//        certificateTableController.didMove(toParentViewController: self)
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
