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
    @IBOutlet weak var passphraseLabel: UILabel!
    var attempts = 5
    
    override func viewDidLoad() {
        title = ""
        
        generatePassphrase()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @IBAction func doneTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    func generatePassphrase() {
        let passphrase = Keychain.generateSeedPhrase()

        do {
            try Keychain.updateShared(with: passphrase)
            passphraseLabel.text = passphrase
        } catch {
            attempts -= 1
            
            if attempts < 0 {
                fatalError("Couldn't generate a passphrase after failing 5 times.")
            } else {
                generatePassphrase()
            }
        }

    }
    
}


@IBDesignable
class RectangularButton : UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .white
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 0.5
        contentEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
    }
}
