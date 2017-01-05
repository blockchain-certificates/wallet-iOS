//
//  ReplacePassphraseViewController.swift
//  wallet
//
//  Created by Chris Downie on 1/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit

class ReplacePassphraseViewController: UIViewController {

    @IBOutlet weak var passphraseField: UITextView!
    
    private var replaceButton : UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Replace Passphrase"
        
        // Do any additional setup after loading the view.
        view.backgroundColor = Colors.baseColor
        replaceButton = UIBarButtonItem(title: "Replace", style: .done, target: self, action: #selector(saveNewPassphrase))
        
        navigationItem.rightBarButtonItem = replaceButton
    }
    
    func saveNewPassphrase() {
        guard let requestedPassphrase = passphraseField.text else {
            return
        }
        
        print(requestedPassphrase)
    }
    
}
