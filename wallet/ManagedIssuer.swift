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
    static let issuerDataConfirmedOn = "issuerDataConfirmedOn"
    static let introducedWithAddress = "introducedWithAddress"
}


class ManagedIssuer : NSObject, NSCoding {
    private(set) var issuer : Issuer?
    
    private(set) var issuerDataConfirmedOn: Date?
    
    var hasConfirmedIssuerData : Bool {
        return issuerDataConfirmedOn != nil
    }
    
    private(set) var introducedWithAddress : String?
    
    var hasIntroduced : Bool {
        return introducedWithAddress != nil
    }
    
    private var inProgressRequest : CommonRequest?

    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    private init(issuer: Issuer?, issuerDataConfirmedOn: Date? = nil, introducedWithAddress: String? = nil) {
        self.issuer = issuer
        self.issuerDataConfirmedOn = issuerDataConfirmedOn
        self.introducedWithAddress = introducedWithAddress
        
        super.init()
    }
    
    // MARK: NSCoding
    required convenience init?(coder decoder: NSCoder) {
        let address = decoder.decodeObject(forKey: CoderKeys.introducedWithAddress) as? String
        var issuer : Issuer?
        let hasConfirmed = decoder.decodeObject(forKey: CoderKeys.issuerDataConfirmedOn) as? Date
        
        if let issuerDictionary = decoder.decodeObject(forKey: CoderKeys.issuer) as? [String: Any] {
            issuer = Issuer(dictionary: issuerDictionary)
        }
        
        self.init(issuer: issuer, issuerDataConfirmedOn: hasConfirmed, introducedWithAddress: address)
    }
    
    func encode(with coder: NSCoder) {
        if let issuer = self.issuer {
            coder.encode(issuer.toDictionary(), forKey: CoderKeys.issuer)
        }
        coder.encode(issuerDataConfirmedOn, forKey: CoderKeys.issuerDataConfirmedOn)
        coder.encode(introducedWithAddress, forKey: CoderKeys.introducedWithAddress)
    }

    
    // MARK: Identification step
    func manage(issuer: Issuer, completion: @escaping (Bool) -> Void) {
        guard self.issuer == nil else {
            print("This manager is called for -- it already has an issuer it's managing.")
            completion(false)
            return
        }
        
        self.issuer = issuer
        getIssuerIdentity(completion: completion)
    }
    
    func getIssuerIdentity(completion: @escaping (Bool) -> Void) {
        guard let issuer = self.issuer else {
            completion(false)
            return
        }
        
        getIssuerIdentity(from: issuer.id, completion: completion)
    }
    
    func getIssuerIdentity(from url: URL, completion: @escaping (Bool) -> Void) {
        let identityRequest = IssuerCreationRequest(id: url) { [weak self] (possibleIssuer) in
            // TODO: Should we do anything with the
            self?.issuer = possibleIssuer
            let success = possibleIssuer != nil
            
            
            completion(success)
            self?.inProgressRequest = nil
            self?.issuerDataConfirmedOn = Date()
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
