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
    
    struct VerifierMessageType {
        static let blockchain = "blockchain"
        static let allSteps = "allSteps"
        static let substepUpdate = "substepUpdate"
        static let result = "result"
    }
    
    let certificate: Data
    var webView: WKWebView?
    var delegate: CertificateVerifierDelegate?
    var blockchain: String?
    
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
    
    var cachePath: String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    }
    
    func verify() {
        setup()
        
        let htmlCopy = URL(fileURLWithPath: NSString(string: cachePath).appendingPathComponent("verify.html"))
        let webView = WKWebView()
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.loadFileURL(htmlCopy, allowingReadAccessTo: URL(fileURLWithPath: cachePath))
        webView.configuration.userContentController.add(self, name: VerifierMessageType.blockchain)
        webView.configuration.userContentController.add(self, name: VerifierMessageType.allSteps)
        webView.configuration.userContentController.add(self, name: VerifierMessageType.substepUpdate)
        webView.configuration.userContentController.add(self, name: VerifierMessageType.result)
        
        self.webView = webView
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message: \(message.body)")
        
        switch message.name {
        case VerifierMessageType.blockchain:
            blockchain = message.body as? String
            let message = Localizations.VerificationInProgress(blockchain!)
            delegate?.updateStatus(message: message, status: .verifying)
            
        case VerifierMessageType.allSteps:
            let topArray = message.body as! [[String: Any?]]
            var allSteps: [VerificationStep] = []
            for step in topArray {
                allSteps.append(VerificationStep(rawObject: step))
            }
            delegate?.notifySteps(steps: allSteps)
            
        case VerifierMessageType.substepUpdate:
            let message = message.body as! [String: Any?]
            let substep = VerificationSubstep(rawObject: message)
            delegate?.updateSubstepStatus(substep: substep)
            
        case VerifierMessageType.result:
            let message = message.body as! [String: Any?]
            let status = message["status"] as! String
            let success = (status == VerificationStatus.success.rawValue)
            
            if success {
                delegate?.updateStatus(message: Localizations.VerificationSuccess(blockchain!), status: .success)
            } else {
                delegate?.updateStatus(message: Localizations.VerificationFail, status: .failure)
            }

        default:
            return
        }
    }
    
    func cleanup() {
        webView = nil
    }
    
    func cancel() {
        cleanup()
    }
}

enum VerificationStatus: String {
    case success = "success"
    case failure = "failure"
    case verifying = "starting"
}

class VerificationStep {
    var code: String!
    var label: String?
    var substeps: [VerificationSubstep] = []
    
    init(rawObject: [String: Any?]) {
        code = rawObject["code"] as? String
        label = rawObject["label"] as? String
        
        let stepArray = rawObject["subSteps"] as! [[String: Any?]]
        for step in stepArray {
            substeps.append(VerificationSubstep(rawObject: step))
        }
    }
}

class VerificationSubstep {
    var code: String!
    var label: String?
    var parentStep: String?
    var errorMessage: String?
    var status: VerificationStatus?
    
    init(rawObject: [String: Any?]) {
        code = rawObject["code"] as? String
        label = rawObject["label"] as? String
        parentStep = rawObject["parentStep"] as? String
        errorMessage = rawObject["errorMessage"] as? String
        
        if let rawStatus = rawObject["status"] as? String {
            status = VerificationStatus(rawValue: rawStatus)
        }
    }
}

protocol CertificateVerifierDelegate: class {
    func updateStatus(message: String, status: VerificationStatus)
    func notifySteps(steps: [VerificationStep])
    func updateSubstepStatus(substep: VerificationSubstep)
}

