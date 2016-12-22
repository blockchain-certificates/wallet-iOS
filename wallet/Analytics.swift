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
        return Analytics(environment: .debug)
    }
    
    public func track(event: AnalyticsEvent, certificate: Certificate) {
        let eventName : String
        switch event {
        case .viewed:
            eventName = "viewed"
        case .validated:
            eventName = "validated"
        case .shared:
            eventName = "shared"
        }
        
        switch environment {
        case .debug:
            print("Tracking \(eventName) for \(certificate.assertion.uid).")
        default:
            print("Tracking for \(environment) environment not implemented yet.")
        }
    }
}
