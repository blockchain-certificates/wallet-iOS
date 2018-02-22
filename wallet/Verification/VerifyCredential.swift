//
//  VerifyCredential.swift
//  certificates
//
//  Created by Quinn McHenry on 2/22/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import Foundation
import WebKit

class VerifyCredential {
    
    let certificate: Data
    var webView: WKWebView?
    var callback: ((Bool, [String]) -> Void)
    var updateTimer: Timer?

    var output = "" {
        didSet {
            if output.contains("success") || output.contains("failure") {
                cleanup()
                process(output)
            }
        }
    }

    func process(_ output: String) {
        let success = output.contains("success")
        let lines = output.split(separator: "\n")
        let steps = lines.prefix(through: max(0, lines.count - 2))
        callback(success, steps.map{ String($0) })
    }
    
    init(certificate: Data, callback: @escaping ((Bool, [String]) -> Void)) {
        self.certificate = certificate
        self.callback = callback
    }
    
    func verify() {
        setup()

        let webView = WKWebView()
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        let htmlCopy = URL(fileURLWithPath: NSString(string: cachePath).appendingPathComponent("verify.html"))
        webView.loadFileURL(htmlCopy, allowingReadAccessTo: URL(fileURLWithPath: cachePath))
        self.webView = webView
        print(cachePath)
        updateTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateOutput), userInfo: nil, repeats: true)
    }
    
    @objc func updateOutput() {
        guard let webView = webView else { return }
        let script = "document.getElementById('output').innerText"
        webView.evaluateJavaScript(script, completionHandler: updateCallback)
    }
    
    func updateCallback(output: Any, error: Error?) {
        if let error = error { print(error) }
        guard let output = output as? String else { return }
        self.output = output
    }
    
    func setup() {
        do {
            // copy html file to cache dir
            let htmlURL = Bundle.main.url(forResource: "verify", withExtension: "html")!
            let htmlCopy = URL(fileURLWithPath: NSString(string: cachePath).appendingPathComponent("verify.html"))
            try FileManager.default.removeItem(at: htmlCopy)
            try FileManager.default.copyItem(at: htmlURL, to: htmlCopy)
            
            // copy js library to cache dir
            let jsURL = Bundle.main.url(forResource: "verifier", withExtension: "js")!
            let jsCopy = URL(fileURLWithPath: NSString(string: cachePath).appendingPathComponent("verifier.js"))
            try FileManager.default.removeItem(at: jsCopy)
            try FileManager.default.copyItem(at: jsURL, to: jsCopy)
            
            // write certificate to cache
            let certString = String(data: certificate, encoding: .utf8)
            let certPath = URL(fileURLWithPath: NSString(string: cachePath).appendingPathComponent("certificate.json"))
            try FileManager.default.removeItem(at: certPath)
            try certString?.write(to: certPath, atomically: true, encoding: .utf8)
        } catch {
            print(error)
        }
    }
    
    func cleanup() {
        updateTimer?.invalidate()
        webView = nil
    }
    
    var cachePath: String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    }
    
}
