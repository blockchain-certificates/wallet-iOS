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
    case debug, auto, staging, production
}

class Analytics {
    let environment : AnalyticsEnvironment
    let privateIdentifier : String
    
    init(environment: AnalyticsEnvironment = .production) {
        privateIdentifier = "TODO"
        self.environment = environment
    }
    
    public static var shared : Analytics {
        return Analytics()
    }
    
    public func track(event: AnalyticsEvent, certificate: Certificate) {
        let actionName : String
        switch event {
        case .viewed:
            actionName = "viewed"
        case .validated:
            actionName = "validated"
        case .shared:
            actionName = "shared"
        }
        
        switch environment {
        case .debug:
            print("Tracking \(actionName) for \(certificate.assertion.uid).")
        case .production:
            let eventDictionary = GAIDictionaryBuilder.createEvent(withCategory: certificate.issuer.id.absoluteString,
                                                                   action: actionName,
                                                                   label: certificate.assertion.uid,
                                                                   value: nil)
            if let tracker = GAI.sharedInstance().defaultTracker,
                let eventData = eventDictionary?.build() {
                tracker.send(eventData as [NSObject: AnyObject])
            }
        default:
            print("Tracking for \(environment) environment not implemented yet.")
        }
    }
    
    public func applicationDidLaunch() {
        // Configure tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        // Optional: configure GAI options.
        let gai : GAI! = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        gai.logger.logLevel = .verbose  // remove before app release
    }
}
