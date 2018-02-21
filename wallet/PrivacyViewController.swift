//
//  PrivacyViewController.swift
//  wallet
//
//  Created by Chris Downie on 2/16/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import WebKit

class PrivacyViewController: UIViewController {
    var webView : WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = NSLocalizedString("Privacy Policy", comment: "Title for the screen with our privacy policy on it.")

        let privacyURL = URL(string: "http://www.learningmachine.com/mobile-privacy.html")!
        let request = URLRequest(url: privacyURL)
        
        webView.load(request)
    }

}


class AboutPassphraseViewController: UIViewController {
    var webView : WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        title = NSLocalizedString("About Passphrase", comment: "Title for the screen with about passphrase info on it.")
        
        let url = URL(string: "http://www.learningmachine.com/about-passphrases/")!
        let request = URLRequest(url: url)
        
        webView.load(request)
    }
    
}





