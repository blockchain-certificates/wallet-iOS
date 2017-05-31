//
//  OnboardingViewController.swift
//  wallet
//
//  Created by Chris Downie on 5/30/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit

class LandingScreenViewController : UIViewController {
    override func viewDidLoad() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        title = ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
}

class RestoreAccountViewController: UIViewController {
    override func viewDidLoad() {
        title = ""
    }
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    @IBAction func doneTapped() {
        dismiss(animated: true, completion: nil)
    }
}

class PrenupViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    override func viewDidLoad() {
        title = ""
    }
}

class GeneratedPassphraseViewController: UIViewController {
    override func viewDidLoad() {
        title = ""
    }
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @IBAction func doneTapped() {
        dismiss(animated: true, completion: nil)
    }
}
