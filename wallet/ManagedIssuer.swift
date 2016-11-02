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
    static let hostedIssuer = "hostedIssuer"
    static let isIssuerConfirmed = "isIssuerConfirmed"
    static let issuerConfirmedOn = "issuerConfirmedOn"
    static let introducedWithAddress = "introducedWithAddress"
}


class ManagedIssuer : NSObject, NSCoding {
    var delegate : ManagedIssuerDelegate?
    
    private(set) var issuer : Issuer?
    private(set) var issuerConfirmedOn: Date?
    private(set) var introducedWithAddress : String?
    private(set) var isIssuerConfirmed = false
    
    private var inProgressRequest : CommonRequest?
    private var hostedIssuer : Issuer?
    
    var status : String {
        if issuer == nil {
            return "No Data"
        }
        if issuerConfirmedOn == nil {
            return "Unconfirmed"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let confirmedDate = formatter.string(from: issuerConfirmedOn!)
        if isIssuerConfirmed {
            return "✅\(confirmedDate)"
        } else {
            return "⛔\(confirmedDate)"
        }
    }

    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    private init(issuer: Issuer?,
                 hostedIssuer: Issuer?,
                 isIssuerConfirmed: Bool = false,
                 issuerConfirmedOn: Date? = nil,
                 introducedWithAddress: String? = nil) {
        self.issuer = issuer
        self.hostedIssuer = hostedIssuer
        self.isIssuerConfirmed = isIssuerConfirmed
        self.issuerConfirmedOn = issuerConfirmedOn
        self.introducedWithAddress = introducedWithAddress
        
        super.init()
    }
    
    // MARK: NSCoding
    required convenience init?(coder decoder: NSCoder) {
        let address = decoder.decodeObject(forKey: CoderKeys.introducedWithAddress) as? String
        var issuer : Issuer?
        var hostedIssuer : Issuer?
        let isConfirmed = decoder.decodeBool(forKey: CoderKeys.isIssuerConfirmed)
        let confirmedDate = decoder.decodeObject(forKey: CoderKeys.issuerConfirmedOn) as? Date
        
        if let issuerDictionary = decoder.decodeObject(forKey: CoderKeys.issuer) as? [String: Any] {
            issuer = Issuer(dictionary: issuerDictionary)
        }
        if let hostedIssuerDictionary = decoder.decodeObject(forKey: CoderKeys.hostedIssuer) as? [String: Any] {
            hostedIssuer = Issuer(dictionary: hostedIssuerDictionary)
        }
        
        self.init(issuer: issuer,
                  hostedIssuer: hostedIssuer,
                  isIssuerConfirmed: isConfirmed,
                  issuerConfirmedOn: confirmedDate,
                  introducedWithAddress: address)
    }
    
    func encode(with coder: NSCoder) {
        if let issuer = self.issuer {
            coder.encode(issuer.toDictionary(), forKey: CoderKeys.issuer)
        }
        if let hostedIssuer = self.hostedIssuer {
            coder.encode(hostedIssuer.toDictionary(), forKey: CoderKeys.hostedIssuer)
        }
        coder.encode(isIssuerConfirmed, forKey: CoderKeys.isIssuerConfirmed)
        coder.encode(issuerConfirmedOn, forKey: CoderKeys.issuerConfirmedOn)
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
        let identityRequest = IssuerIdentificationRequest(id: url) { [weak self] (possibleIssuer) in
            var success = possibleIssuer != nil
            
            self?.hostedIssuer = possibleIssuer
            
            if self?.issuer == nil {
                self?.issuer = possibleIssuer
            } else if possibleIssuer != nil {
                // We had an issuer, and we got an issuer. They need to have the same ID to be valid.
                success = (self?.issuer?.id == possibleIssuer?.id)
            }
                
            self?.inProgressRequest = nil
            self?.issuerConfirmedOn = Date()
            self?.isIssuerConfirmed = success
            
            completion(success)
            
            if self != nil {
                self!.delegate?.updated(managedIssuer: self!)
            }
        }
        identityRequest.start()
        self.inProgressRequest = identityRequest
    }
}


protocol ManagedIssuerDelegate : class {
    func updated(managedIssuer: ManagedIssuer)
}
