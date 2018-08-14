//
//  CertificateVerifier.swift
//  certificates
//
//  Created by Michael Shin on 8/14/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import Foundation
import WebKit

class CertificateVerifier: NSObject, WKScriptMessageHandler {
    
    enum Status: String {
        case success = "success"
        case failure = "failure"
        case inProgress = "starting"
    }
    
    struct VerifierMessage {
        let code: String
        let label: String
        let status: Status
        let errorMessage: String
    }
    
    let certificate: Data
    var webView: WKWebView?
    var delegate: CertificateVerifierDelegate?
    var chain: BlockChain?
    
    var cachePath: String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    }
    
    init(certificate: Data) {
        self.certificate = certificate
    }
    
    func setup() {
        // copy html file to cache dir
        let htmlURL = Bundle.main.url(forResource: "verify", withExtension: "html")!
        let htmlCopy = URL(fileURLWithPath: NSString(string: cachePath).appendingPathComponent("verify.html"))
        try? FileManager.default.removeItem(at: htmlCopy)
        try! FileManager.default.copyItem(at: htmlURL, to: htmlCopy)
        
        // copy js library to cache dir
        let jsURL = Bundle.main.url(forResource: "verifier", withExtension: "js")!
        let jsCopy = URL(fileURLWithPath: NSString(string: cachePath).appendingPathComponent("verifier.js"))
        try? FileManager.default.removeItem(at: jsCopy)
        try! FileManager.default.copyItem(at: jsURL, to: jsCopy)
        
        // write certificate to cache
        let certString = String(data: certificate, encoding: .utf8)
        let certPath = URL(fileURLWithPath: NSString(string: cachePath).appendingPathComponent("certificate.json"))
        try? FileManager.default.removeItem(at: certPath)
        try! certString?.write(to: certPath, atomically: true, encoding: .utf8)
    }
    
    func verify() {
        setup()
        
        let htmlCopy = URL(fileURLWithPath: NSString(string: cachePath).appendingPathComponent("verify.html"))
        let webView = WKWebView()
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.loadFileURL(htmlCopy, allowingReadAccessTo: URL(fileURLWithPath: cachePath))
        webView.configuration.userContentController.add(self, name: "scriptHandler")
        
        self.webView = webView
        
        do {
            // TODO: See if this is still necessary
        } catch {
            Logger.main.info("JSON parsing error during verification: \(error)")
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message: \(message.body)")
    }
    
    func cleanup() {
        webView = nil
    }
    
    func cancel() {
        cleanup()
    }
}

enum BlockChain: String {
    case mainnet = "bitcoinMainnet"
    case testnet = "bitcoinTestnet"
    case mocknet = "mockchain"
}

protocol CertificateVerifierDelegate: class {
    func start(blockChain: BlockChain)
    func startStep(code: String, label: String)
    func startSubstep(code: String, label: String)
    func finishSubstep(code: String, success: Bool, errorMessage: String?)
    func finish(success: Bool, errorMessage: String?)
}

