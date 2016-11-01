//
//  File.swift
//  wallet
//
//  Created by Chris Downie on 11/1/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import Foundation
import BlockchainCertificates

class ManagedIssuer {
    var issuer : Issuer?
    
    var isVerified : Bool {
        get {
            return issuer != nil
        }
    }
    
    var introducedWithAddress : String?
    var hasIntroduced : Bool {
        get {
            return introducedWithAddress != nil
        }
    }
    
    private var inProgressRequest : CommonRequest?

    init() {
    }
    
//
//    init(issuer: Issuer) {
//        self.issuer = issuer
//    }

    func getIssuerIdentity(from url: URL, completion: @escaping (Bool) -> Void) {
        let identityRequest = IssuerCreationRequest(id: url) { [weak self] (possibleIssuer) in
            self?.issuer = possibleIssuer
            let success = possibleIssuer != nil
            
            completion(success)
            self?.inProgressRequest = nil
        }
        identityRequest.start()
        self.inProgressRequest = identityRequest
    }
    
    /// Contacts the Issuer's URL to update the issuer data.
    ///
    /// - returns: True iff the underlying issuer model changes.
    public func update() -> Bool {
        return false
    }
    
}
