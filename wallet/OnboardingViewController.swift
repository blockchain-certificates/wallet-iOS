//
//  OnboardingViewController.swift
//  wallet
//
//  Created by Chris Downie on 5/30/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit

class OnboardingViewController: UIViewController {
    override func loadView() {
        let container = UIView()
        let icon = UIImageView(image: #imageLiteral(resourceName: "Logo"))
        let newAccountButton = UIButton(type: .custom)
        newAccountButton.setTitle(NSLocalizedString("New Account", comment: "Onboarding flow button that states the user would like a new account"), for: .normal)
        
        let existingAccountButton = UIButton(type: .custom)
        existingAccountButton.setTitle(NSLocalizedString("I Already Have One", comment: "Onboarding flow button where the user would like to use an existing account"), for: .normal)
        
        //        let buttons = UIStackView(arrangedSubviews: [newAccountButton, existingAccountButton])
        //        buttons.axis = .vertical
        
        container.addSubview(icon)
        container.addSubview(newAccountButton)
        container.addSubview(existingAccountButton)
        
        view = container
        
        let views = [
            "icon": icon,
            "newAccountButton": newAccountButton,
            "existingAccountButton": existingAccountButton
        ]
        let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[icon]-[newAccountButton]-[existingAccountButton]", options: .alignAllCenterX, metrics: nil, views: views)
        NSLayoutConstraint.activate(constraints)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
