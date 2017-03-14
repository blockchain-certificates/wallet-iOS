//
//  Analytics.swift
//  wallet
//
//  Created by Chris Downie on 12/22/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import Foundation
import BlockchainCertificates

enum AnalyticsEvent {
    case viewed, validated, shared
}
enum AnalyticsEnvironment {
    case debug, development, staging, production
}

class Analytics {
    var tasks = [URLRequest : URLSessionDataTask]()
    let environment : AnalyticsEnvironment
    var tracker : GAITracker?
    
    init(environment: AnalyticsEnvironment = .production) {
        self.environment = environment
    }
    
    public static var shared : Analytics {
        return Analytics(environment: .development)
    }
    
    public func track(event: AnalyticsEvent, certificate: Certificate) {
        switch environment {
        case .debug:
            print("Tracking \(certificate.assertion.uid).")
        case .development:
            // Development and Production environments both track as if in Production
            fallthrough
        case .production:
            // Tracking with Google Analytics
            reportToGoogle(action: event, for: certificate)
            
            // Tracking with custom analytics
            reportToLearningMachine(action: event, for: certificate)

        default:
            print("Tracking for \(environment) environment not implemented yet.")
        }
        
    }
    
    func reportToGoogle(action: AnalyticsEvent, for certificate: Certificate) {
        let actionName : String
        switch action {
        case .viewed:
            actionName = "viewed"
        case .validated:
            actionName = "validated"
        case .shared:
            actionName = "shared"
        }
        
        if tracker == nil {
            tracker = GAI.sharedInstance().defaultTracker
        }
        guard let tracker = tracker else {
            print("Unable to access the shared tracker to record this \(action) event.")
            return
        }

        let eventDictionary = GAIDictionaryBuilder.createEvent(withCategory: certificate.issuer.id.absoluteString,
                                                               action: actionName,
                                                               label: certificate.assertion.uid,
                                                               value: nil)
        guard let eventData = eventDictionary?.build() else {
            print("Couldn't build an event dictionary for \(action) event.")
            return
        }
        
        tracker.send(eventData as [NSObject: AnyObject])
    }
    
    func reportToLearningMachine(action: AnalyticsEvent, for certificate: Certificate) {
        let actionName : String
        switch action {
        case .viewed:
            actionName = "viewed"
        case .validated:
            actionName = "verified"
        case .shared:
            actionName = "shared"
        }
        
        let payload : [String : Any] = [
            "key": certificate.assertion.uid, //certificate.assertion.id.absoluteString,
            "action": actionName,
            "metadata" : [
                "application": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
                "platform": "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
            ]
        ]
        
        var uploadRequest = URLRequest(url: URL(string: "https://certificates.learningmachine.com/api/event/certificate")!)
        uploadRequest.httpMethod = "POST"
        uploadRequest.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        uploadRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        uploadRequest.setValue("application/json", forHTTPHeaderField: "Accepts")
        
        let uploadTask : URLSessionDataTask = URLSession.shared.dataTask(with: uploadRequest as URLRequest) { [weak self] (data, response, error) in
            guard error == nil else {
                print("Got an error trying to report \(action) event for \(certificate.assertion.id)")
                dump(error!)
                dump(response)
                return
            }
            
            _ = self?.tasks.removeValue(forKey: uploadRequest)
        }
        tasks[uploadRequest] = uploadTask
        uploadTask.resume()
    }
    
    public func applicationDidLaunch() {
        // Configure tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        let gai : GAI! = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        gai.logger.logLevel = .verbose
    }
}
