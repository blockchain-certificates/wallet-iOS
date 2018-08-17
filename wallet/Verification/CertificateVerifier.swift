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
    
    struct VerifierMessageType {
        static let blockchain = "blockchain"
        static let allSteps = "allSteps"
        static let substepUpdate = "substepUpdate"
        static let result = "result"
    }
    
    class VerifierStep {
        var code: String!
        var label: String!
        var labelPending: String?
        var parentStep: String?
        var status: Status?
        var errorMessage: String?
        
        func set(dictionary: [String: Any]) {
            code = dictionary["code"] as! String
            label = dictionary["label"] as! String
            
            if let labelPending = dictionary["labelPending"] as? String {
                self.labelPending = labelPending
            }
            
            if let parentStep = dictionary["parentStep"] as? String {
                self.parentStep = parentStep
            }
            
            if let errorMessage = dictionary["errorMessage"] as? String {
                self.errorMessage = errorMessage
            }
            
            if let statusStr = dictionary["status"] as? String {
                status = Status(rawValue: statusStr)
            }
        }
    }
    
    let certificate: Data
    var webView: WKWebView?
    var delegate: CertificateVerifierDelegate?
    var chain: BlockChain?
    var steps = [String: VerifierStep]()
    var substeps = [String: VerifierStep]()
    
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
        webView.configuration.userContentController.add(self, name: VerifierMessageType.blockchain)
        webView.configuration.userContentController.add(self, name: VerifierMessageType.allSteps)
        webView.configuration.userContentController.add(self, name: VerifierMessageType.substepUpdate)
        webView.configuration.userContentController.add(self, name: VerifierMessageType.result)
        
        self.webView = webView
        
        do {
            // TODO: See if this is still necessary
        } catch {
            Logger.main.info("JSON parsing error during verification: \(error)")
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message: \(message.body)")
        
        switch message.name {
        case VerifierMessageType.blockchain:
            break
            
        case VerifierMessageType.allSteps: // TODO: Write non-shit code
            let stepArr = message.body as! [Any]
            for stepObj in stepArr {
                let stepDict = stepObj as! [String: Any]
                let step = VerifierStep()
                step.set(dictionary: stepDict)
                steps[step.code] = step
                
                let substepArr = stepDict["subSteps"] as! [Any]
                for substepObj in substepArr {
                    let substepDict = substepObj as! [String: Any]
                    let substep = VerifierStep()
                    substep.set(dictionary: substepDict)
                    substeps[substep.code] = substep
                }
            }
            
        case VerifierMessageType.substepUpdate: // TODO: Write non-shit code
            let substepObj = message.body as! [String: Any]
            let substepObjKey = substepObj["code"] as! String
            let substep = substeps[substepObjKey]!
            substep.set(dictionary: substepObj)
            substeps[substepObjKey] = substep
            let step = steps[substep.parentStep!]!
            delegate?.startSubstep(stepLabel: step.label, substepLabel: substep.label)
            
        case VerifierMessageType.result:
            let message = message.body as! [String: String]
            let status = message["status"]!
            let success = status == Status.success.rawValue
            let errorMessage = message["errorMessage"]
            delegate?.finish(success: success, errorMessage: errorMessage)
            
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

enum BlockChain: String {
    case mainnet = "bitcoinMainnet"
    case testnet = "bitcoinTestnet"
    case mocknet = "mockchain"
}

protocol CertificateVerifierDelegate: class {
    func start(blockChain: BlockChain)
    func startSubstep(stepLabel: String, substepLabel: String)
    func finishSubstep(success: Bool, errorMessage: String?)
    func finish(success: Bool, errorMessage: String?)
}

