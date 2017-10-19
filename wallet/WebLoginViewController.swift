//
//  WebLoginViewController.swift
//  wallet
//
//  Created by Chris Downie on 5/30/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import WebKit

class WebLoginViewController: UIViewController {
    let url : URL
    weak var navigationDelegate : WKNavigationDelegate?
    let cancelCallback : () -> Void
    
    var webView : WKWebView!
    
    init(requesting: URL, navigationDelegate: WKNavigationDelegate, onCancel: @escaping () -> Void) {
        url = requesting
        self.navigationDelegate = navigationDelegate
        cancelCallback = onCancel
        super.init(nibName: nil, bundle: nil)
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("Not implemented")
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = navigationDelegate

        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = URLRequest(url: url)
        webView.load(request)

        // Add some chrome when presented in a nav controller
        title = "Log In To Issuer"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelWebLogin))
    }
    
    @objc func cancelWebLogin() {
        cancelCallback()
    }
}
