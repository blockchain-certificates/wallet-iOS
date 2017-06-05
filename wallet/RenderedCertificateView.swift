//
//  RCView.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/23/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit
import WebKit
import Blockcerts

class RenderedCertificateView: UIView {

    @IBOutlet var view: UIView!
    
    @IBOutlet weak var paperView: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var certificateIcon: UIImageView!
    
    @IBOutlet weak var signatureStack: UIStackView!
    
    @IBOutlet weak var sealIcon: UIImageView!

    weak var webView: WKWebView!
    var webViewHeightConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("RenderedCertificateView", owner: self, options: nil)
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraint(NSLayoutConstraint(item: view, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: view, attribute: .left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: view, attribute: .right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: .right, multiplier: 1, constant: 0))
        
        loadWebView()
    }
    deinit {
        webView.removeObserver(self, forKeyPath: "scrollView.contentSize")
    }
    
    private func loadWebView() {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = false
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        

        let frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        let renderer = WKWebView(frame: frame, configuration: configuration)
        
        // Constraints
        view.addSubview(renderer)
        renderer.translatesAutoresizingMaskIntoConstraints = false
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "|[view]|", options: .alignAllCenterX, metrics: nil, views: ["view": renderer])
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: .alignAllCenterY, metrics: nil, views: ["view":renderer]))
        NSLayoutConstraint.activate(constraints)
        
        renderer.isHidden = false
        
        webView = renderer
        webView.addObserver(self, forKeyPath: "scrollView.contentSize", options: .new, context: nil)
        
        webViewHeightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: webView.scrollView.contentSize.height)

    }
    
    func render(certificate: Certificate) {
        if let html = certificate.htmlDisplay {
            let normalizeCss = "/*! normalize.css v7.0.0 | MIT License | github.com/necolas/normalize.css */html{line-height:1.15;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}body{margin:0}article,aside,footer,header,nav,section{display:block}h1{font-size:2em;margin:.67em 0}figcaption,figure,main{display:block}figure{margin:1em 40px}hr{box-sizing:content-box;height:0;overflow:visible}pre{font-family:monospace,monospace;font-size:1em}a{background-color:transparent;-webkit-text-decoration-skip:objects}abbr[title]{border-bottom:none;text-decoration:underline;text-decoration:underline dotted}b,strong{font-weight:inherit}b,strong{font-weight:bolder}code,kbd,samp{font-family:monospace,monospace;font-size:1em}dfn{font-style:italic}mark{background-color:#ff0;color:#000}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sub{bottom:-.25em}sup{top:-.5em}audio,video{display:inline-block}audio:not([controls]){display:none;height:0}img{border-style:none}svg:not(:root){overflow:hidden}button,input,optgroup,select,textarea{font-family:sans-serif;font-size:100%;line-height:1.15;margin:0}button,input{overflow:visible}button,select{text-transform:none}[type=reset],[type=submit],button,html [type=button]{-webkit-appearance:button}[type=button]::-moz-focus-inner,[type=reset]::-moz-focus-inner,[type=submit]::-moz-focus-inner,button::-moz-focus-inner{border-style:none;padding:0}[type=button]:-moz-focusring,[type=reset]:-moz-focusring,[type=submit]:-moz-focusring,button:-moz-focusring{outline:1px dotted ButtonText}fieldset{padding:.35em .75em .625em}legend{box-sizing:border-box;color:inherit;display:table;max-width:100%;padding:0;white-space:normal}progress{display:inline-block;vertical-align:baseline}textarea{overflow:auto}[type=checkbox],[type=radio]{box-sizing:border-box;padding:0}[type=number]::-webkit-inner-spin-button,[type=number]::-webkit-outer-spin-button{height:auto}[type=search]{-webkit-appearance:textfield;outline-offset:-2px}[type=search]::-webkit-search-cancel-button,[type=search]::-webkit-search-decoration{-webkit-appearance:none}::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}details,menu{display:block}summary{display:list-item}canvas{display:inline-block}template{display:none}[hidden]{display:none}/*# sourceMappingURL=normalize.min.css.map */"
            let customCss = "body {padding: 20px; font-size: 12px; line-height: 1.5;} body > section { padding: 0;} body section { max-width: 100%; } body img { max-width: 100%; height: auto; width: inherit; }"
            let wrappedHtml = "<!doctype html><html class=\"no-js\" lang=\"\"><head><meta charset=\"utf-8\"><meta http-equiv=\"x-ua-compatible\" content=\"ie=edge\"><title></title><meta content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0\" name=\"viewport\" /><meta name=”viewport” content=”width=device-width” /><style type=\"text/css\">\(normalizeCss)</style><style type=\"text/css\">\(customCss)</style></head><body>\(html)</body></html>"
            
            webView.isHidden = false
            webView.loadHTMLString(wrappedHtml, baseURL: nil)
            webViewHeightConstraint.isActive = true
        } else {
            webView.isHidden = true
            webViewHeightConstraint.isActive = false
            
            certificateIcon.image = UIImage(data:certificate.issuer.image)
            nameLabel.text = "\(certificate.recipient.givenName) \(certificate.recipient.familyName)"
            titleLabel.text = certificate.title
            subtitleLabel.text = certificate.subtitle
            descriptionLabel.text = certificate.description
            sealIcon.image = UIImage(data: certificate.image)
            
            certificate.assertion.signatureImages.forEach { (signatureImage) in
                guard let image = UIImage(data: signatureImage.image) else {
                    return
                }
                addSignature(image: image, title: signatureImage.title)
            }
        }
    }
    
    
    func clearSignatures() {
        signatureStack.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
    }
    
    func addSignature(image: UIImage, title: String?) {
        if title == nil {
            let subview = UIImageView(image: image)
            signatureStack.addArrangedSubview(subview)
        } else {
            let subview = createTitledSignature(signature: image, title: title!)
            signatureStack.addArrangedSubview(subview)
        }
        updateConstraints()
    }
    
    func createTitledSignature(signature: UIImage, title titleString: String) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure all the subviews
        let signature = UIImageView(image: signature)
        signature.contentMode = .scaleAspectFit
        signature.translatesAutoresizingMaskIntoConstraints = false
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = UIFont.systemFont(ofSize: 11)
        title.text = titleString
        
        view.addSubview(signature)
        view.addSubview(title)

        
        // Now do all the auto-layout.
        let namedViews = [
            "signature": signature,
            "title": title
        ]
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[signature]-[title]|", options: .alignAllCenterX, metrics: nil, views: namedViews)
        let maxWidth : CGFloat = 150
        var signatureConstraints = [
            NSLayoutConstraint(item: signature, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: maxWidth)
        ]
        if signature.bounds.width > maxWidth {
            let expectedHeight = signature.bounds.height * maxWidth / signature.bounds.width
            signatureConstraints.append(NSLayoutConstraint(item: signature, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: expectedHeight))
        }
        let centerConstraints = [
            NSLayoutConstraint(item: signature, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        ]

        NSLayoutConstraint.activate(signatureConstraints)
        NSLayoutConstraint.activate(verticalConstraints)
        NSLayoutConstraint.activate(centerConstraints)
        
        return view
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "scrollView.contentSize" && webView == object as? WKWebView {
            scrollViewContentHeightChanged()
        }
    }
    
    func scrollViewContentHeightChanged() {
        webViewHeightConstraint.constant = webView.scrollView.contentSize.height
    }
}
