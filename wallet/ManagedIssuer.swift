//
//  File.swift
//  wallet
//
//  Created by Chris Downie on 11/1/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import Foundation
import BlockchainCertificates

fileprivate enum CoderKeys {
    static let issuer = "issuer"
    static let introducedWithAddress = "introducedWithAddress"
}


class ManagedIssuer : NSObject, NSCoding {
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

    override init() {
        super.init()
    }
    
    init(issuer: Issuer?, introducedWithAddress: String? = nil) {
        self.issuer = issuer
        self.introducedWithAddress = introducedWithAddress
        
        super.init()
    }
    
//
//    init(issuer: Issuer) {
//        self.issuer = issuer
//    }

    func getIssuerIdentity(completion: @escaping (Bool) -> Void) {
        guard let issuer = self.issuer else {
            completion(false)
            return
        }
        
        getIssuerIdentity(from: issuer.id, completion: completion)
    }
    
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
    
    
    // NSCoding
    required convenience init?(coder decoder: NSCoder) {
        let address = decoder.decodeObject(forKey: CoderKeys.introducedWithAddress) as? String
        var issuer : Issuer?
        
        if let issuerDictionary = decoder.decodeObject(forKey: CoderKeys.issuer) as? [String: Any] {
            issuer = Issuer(dictionary: issuerDictionary)
        }
        
        self.init(issuer: issuer, introducedWithAddress: address)
    }
    
    func encode(with coder: NSCoder) {
        if let issuer = self.issuer {
            coder.encode(issuer.toDictionary(), forKey: CoderKeys.issuer)
        }
        coder.encode(self.introducedWithAddress, forKey: CoderKeys.introducedWithAddress)
    }
}
