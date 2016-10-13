//
//  CertificateViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/13/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit

class CertificateViewController: UIViewController {
    @IBOutlet weak var toolbar: UIToolbar!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Certificate"
        
        // Remove "Info" button in xib and replace it with information disclosure button
        _ = self.toolbar.items?.popLast()
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(infoTapped(_:)), for: .touchUpInside)
        let infoBarButton = UIBarButtonItem(customView: infoButton)
        self.toolbar.items?.append(infoBarButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    @IBAction func shareTapped(_ sender: UIBarButtonItem) {
        print("\(#function)")
    }
    
    @IBAction func verifyTapped(_ sender: UIBarButtonItem) {
        print("\(#function)")
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
