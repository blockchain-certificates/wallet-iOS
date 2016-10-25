//
//  AddIssuerViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/13/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit

class AddIssuerViewController: UIViewController {
    @IBOutlet weak var issuerURLField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func saveIssuerTapped(_ sender: UIBarButtonItem) {
        
        dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}
