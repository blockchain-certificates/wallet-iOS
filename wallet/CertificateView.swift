//
//  CertificateView.swift
//  wallet
//
//  Created by Chris Downie on 5/16/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts
import WebKit

class CertificateView: UIView {
    var webView : WKWebView?
    var renderedView : RenderedCertificateView?
    
    var certificate : Certificate {
        didSet {
            render()
        }
    }
    
    
    
    override init(frame: CGRect) {
        fatalError("Should call init(certificate:frame:)")
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(certificate: Certificate, frame: CGRect = .zero) {
        self.certificate = certificate
        
        super.init(frame: frame)
        
        render()
    }
    
    private func render() {
        self.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        
        let possibleNil: Bool? = nil
//        if (certificate.htmlDisplay != nil) {
        if possibleNil != nil {
            loadWebView()
        } else {
            loadRenderedView()
        }
    }
    
    private func loadWebView() {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = false
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        let renderer = WKWebView(frame: .zero, configuration: configuration)
        
        // Constraints
        addSubview(renderer)
        renderer.leadingAnchor.constraint(equalTo: leadingAnchor)
        renderer.trailingAnchor.constraint(equalTo: trailingAnchor)
        renderer.topAnchor.constraint(equalTo: topAnchor)
        renderer.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        webView = renderer
    }
    
    private func loadRenderedView() {
        let renderedCertificateView = RenderedCertificateView(frame: .zero)
        
        addSubview(renderedCertificateView)
        renderedCertificateView.leadingAnchor.constraint(equalTo: leadingAnchor)
        renderedCertificateView.trailingAnchor.constraint(equalTo: trailingAnchor)
        renderedCertificateView.topAnchor.constraint(equalTo: topAnchor)
        renderedCertificateView.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        renderedCertificateView.certificateIcon.image = UIImage(data:certificate.issuer.image)
        renderedCertificateView.nameLabel.text = "\(certificate.recipient.givenName) \(certificate.recipient.familyName)"
        renderedCertificateView.titleLabel.text = certificate.title
        renderedCertificateView.subtitleLabel.text = certificate.subtitle
        renderedCertificateView.descriptionLabel.text = certificate.description
        renderedCertificateView.sealIcon.image = UIImage(data: certificate.image)
        
        certificate.assertion.signatureImages.forEach { (signatureImage) in
            guard let image = UIImage(data: signatureImage.image) else {
                return
            }
            renderedCertificateView.addSignature(image: image, title: signatureImage.title)
        }
        
        renderedView = renderedCertificateView
    }
    
    
    

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */


}
