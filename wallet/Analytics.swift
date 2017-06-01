//
//  Analytics.swift
//  wallet
//
//  Created by Chris Downie on 12/22/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import Foundation
import Blockcerts

enum AnalyticsEvent {
    case viewed, validated, shared
}
enum AnalyticsEnvironment {
    case debug, production
}

class Analytics {
    var tasks = [URLRequest : URLSessionDataTask]()
    let environment : AnalyticsEnvironment
    
    init(environment: AnalyticsEnvironment = .production) {
        self.environment = environment
    }
    
    public func track(event: AnalyticsEvent, certificate: Certificate) {
        switch environment {
        case .debug:
            print("Tracking \(certificate.assertion.uid).")
        case .production:
            // Tracking with custom analytics
            report(action: event, for: certificate)
        }
        
    }

    func report(action: AnalyticsEvent, for certificate: Certificate) {
        let actionName : String
        switch action {
        case .viewed:
            actionName = "viewed"
        case .validated:
            actionName = "verified"
        case .shared:
            actionName = "shared"
        }
        
        let downloadIssuerTask : URLSessionDataTask = URLSession.shared.dataTask(with: certificate.issuer.id) { [weak self] (issuerData, response, error) in
            guard error == nil else {
                print("Got an error requesting data from \(certificate.issuer.id)")
                return
            }
            guard let issuerData = issuerData,
                let parsedJSON = try? JSONSerialization.jsonObject(with: issuerData, options: []),
                let json = parsedJSON as? [String: Any] else {
                print("GET \(certificate.issuer.id) did not respond with JSON data.")
                    return
            }
            
            let issuer: Issuer!
            do {
                issuer = try Issuer(dictionary: json)
            } catch {
                print("Couldn't parse JSON as an issuer from \(certificate.issuer.id)")
                return
            }
            
            if let analyticsURL = issuer.analyticsURL {
                self?.submitReport(actionName: actionName, for: certificate, to: analyticsURL)
            }
        }
        downloadIssuerTask.resume()
        
    }
    
    func submitReport(actionName action: String, for certificate: Certificate, to url: URL) {
        let payload : [String : Any] = [
            "key": certificate.id,
            "action": action,
            "application": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            "platform": "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        ]
        
        var uploadRequest = URLRequest(url: url)
        uploadRequest.httpMethod = "POST"
        uploadRequest.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        uploadRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        uploadRequest.setValue("application/json", forHTTPHeaderField: "Accepts")
        
        let uploadTask : URLSessionDataTask = URLSession.shared.dataTask(with: uploadRequest as URLRequest) { [weak self] (data, response, error) in
            guard error == nil else {
                print("Got an error trying to report \(action) event for \(String(describing: certificate.assertion.id))")
                dump(error!)
                dump(response)
                return
            }
            
            _ = self?.tasks.removeValue(forKey: uploadRequest)
        }
        tasks[uploadRequest] = uploadTask
        uploadTask.resume()
    }
}
