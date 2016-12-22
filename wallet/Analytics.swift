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
    let environment : AnalyticsEnvironment
    var tracker : GAITracker?
    
    init(environment: AnalyticsEnvironment = .production) {
        self.environment = environment
    }
    
    public static var shared : Analytics {
        return Analytics(environment: .development)
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
        case .development:
            // Development and Production environments both track with Google Analytics
            fallthrough
        case .production:
            if tracker == nil {
                tracker = GAI.sharedInstance().defaultTracker
            }
            guard let tracker = tracker else {
                print("Unable to access the shared tracker to record this \(actionName) event.")
                return
            }
            let eventDictionary = GAIDictionaryBuilder.createEvent(withCategory: certificate.issuer.id.absoluteString,
                                                                   action: actionName,
                                                                   label: certificate.assertion.uid,
                                                                   value: nil)
            guard let eventData = eventDictionary?.build() else {
                print("Couldn't build an event dictionary for \(actionName) event.")
                return
            }
            
            tracker.send(eventData as [NSObject: AnyObject])
        default:
            print("Tracking for \(environment) environment not implemented yet.")
        }
    }
    
    public func applicationDidLaunch() {
        // Configure tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        let gai : GAI! = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        gai.logger.logLevel = .verbose
//        tracker = gai.defaultTracker

        // This would be even better as a build-time option instead of a run-time option.
//        var trackingID : String?
//        if environment == .production {
//            trackingID = "UA-89352488-1"
//        } else if environment == .development {
//            trackingID = "UA-89352488-2"
//        }
//        
//        if let trackingID = trackingID {
//            tracker = gai.tracker(withTrackingId: trackingID)
//        }
        
    }
}
