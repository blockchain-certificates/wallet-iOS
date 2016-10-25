//
//  AccountViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/13/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {
    private let firstNameKey = "ACCOUNT_FIRST_NAME"
    private let lastNameKey = "ACCOUNT_LAST_NAME"
    private let emailKey = "ACCOUNT_EMAIL"

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationBar.backgroundColor = Colors.brandColor
        navigationBar.tintColor = Colors.tintColor
//        navigationBar.titleTextAttributes = [
//            NSForegroundColorAttributeName: Colors.tintColor
//        ]
        loadAccount()
    }
    override func viewWillDisappear(_ animated: Bool) {
        // 
        saveAccount()
    }

    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func loadAccount() {
        let firstName = UserDefaults.standard.string(forKey: firstNameKey)
        let lastName = UserDefaults.standard.string(forKey: lastNameKey)
        let email = UserDefaults.standard.string(forKey: emailKey)
        
        firstNameField.text = firstName
        lastNameField.text = lastName
        emailField.text = email
    }
    
    func saveAccount() {
        UserDefaults.standard.set(firstNameField.text, forKey: firstNameKey)
        UserDefaults.standard.set(lastNameField.text, forKey: lastNameKey)
        UserDefaults.standard.set(emailField.text, forKey: emailKey)
    }
}
