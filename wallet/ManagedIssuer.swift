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

enum InvalidIssuerReason {
    case missing, invalid
}

enum InvalidIssuerScope {
    case response, json, property(named: String)
}

enum ManagedIssuerError {
    case genericError
    case invalidState(reason: String)
    case untrustworthyIssuer(reason: String)
    case abortedIdentificationStep
    case issuerInvalid(reason: InvalidIssuerReason, scope: InvalidIssuerScope)
    case serverError(code: Int)

}

class ManagedIssuer : NSObject, NSCoding {
    var delegate : ManagedIssuerDelegate?
    var issuerDescription : String?
    
    private(set) var issuer : Issuer?
    private(set) var issuerConfirmedOn: Date?
    private(set) var isIssuerConfirmed = false
    
    private(set) var introducedWithAddress : String?
    private(set) var introducedOn: Date?
    
    private var inProgressRequest : CommonRequest?
    private var hostedIssuer : Issuer?
    
    fileprivate var nonce : String?

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
            issuer = try? Issuer(dictionary: issuerDictionary)
        }
        if let hostedIssuerDictionary = decoder.decodeObject(forKey: CoderKeys.hostedIssuer) as? [String: Any] {
            hostedIssuer = try? Issuer(dictionary: hostedIssuerDictionary)
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
    func manage(issuer: Issuer, completion: @escaping (ManagedIssuerError?) -> Void) {
        guard self.issuer == nil else {
            completion(.invalidState(reason: "This manager is called for -- it already has an issuer it's managing."))
            return
        }
        
        self.issuer = issuer
        getIssuerIdentity(completion: completion)
    }
    
    func getIssuerIdentity(completion: @escaping (ManagedIssuerError?) -> Void) {
        guard let issuer = self.issuer else {
            completion(.invalidState(reason: "Can't call \(#function) when Issuer isn't set. Use manage(issuer:completion:) instead."))
            return
        }
        
        getIssuerIdentity(from: issuer.id, completion: completion)
    }
    
    func getIssuerIdentity(from url: URL, completion: @escaping (ManagedIssuerError?) -> Void) {
        let identityRequest = IssuerIdentificationRequest(id: url) { [weak self] (possibleIssuer, error) in
            var returnError : ManagedIssuerError? = nil
            
            self?.inProgressRequest = nil
            self?.issuerConfirmedOn = Date()
            self?.hostedIssuer = possibleIssuer
            self?.isIssuerConfirmed = (error == nil)
            
            if self?.issuer == nil {
                self?.issuer = possibleIssuer
            } else if possibleIssuer != nil && self?.issuer?.id != possibleIssuer?.id {
                returnError = .untrustworthyIssuer(reason:"The issuer we're managing has a different ID in the issuer's JSON. This means the issuer's hosting JSON has changed ownership.")
            }
            
            if let error = error {
                self?.isIssuerConfirmed = false
                
                switch (error) {
                case .aborted:
                    returnError = .abortedIdentificationStep
                case .missingJSONData:
                    returnError = .issuerInvalid(reason: .missing, scope: .json)
                case .jsonSerializationFailure:
                    returnError = .issuerInvalid(reason: .invalid, scope: .json)
                case .issuerMissing(let property):
                    returnError = .issuerInvalid(reason: .missing, scope: .property(named: property))
                case .issuerInvalid(let property):
                    returnError = .issuerInvalid(reason: .invalid, scope: .property(named: property))
                case .httpFailure(let status, _):
                    returnError = .serverError(code: status)
                    
                case .unknownResponse:
                    fallthrough
                default:
                    returnError = .genericError
                }
            }

            // Call the completion handler, and the delegate as the last thing we do.
            completion(returnError)
            
            if self != nil {
                self!.delegate?.updated(managedIssuer: self!)
            }
        }
        inProgressRequest?.abort()
        identityRequest.start()
        inProgressRequest = identityRequest
    }
    
    func introduce(recipient: Recipient, with nonce: String, completion: @escaping (Bool) -> Void) {
        guard let issuer = issuer else {
            completion(false)
            return
        }
        
        self.nonce = nonce
        let introductionRequest = IssuerIntroductionRequest(introduce: recipient, to: issuer) { [weak self] (error) in
            let success =  (error == nil)
            if success {
                self?.introducedWithAddress = recipient.publicAddress
            } else {
                self?.introducedWithAddress = nil
            }
            self?.introducedOn = Date()
            self?.inProgressRequest = nil
            
            completion(success)
        }
        introductionRequest.delegate = self
        inProgressRequest?.abort()
        introductionRequest.start()
        inProgressRequest = introductionRequest
    }
}

// Debug properties
extension ManagedIssuer {
    override var debugDescription : String {
        if issuer == nil {
            return "No Data"
        }
        if issuerConfirmedOn == nil {
            return "Unconfirmed"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        let confirmedDate = formatter.string(from: issuerConfirmedOn!)
        
        if introducedOn == nil {
            return "Confirmed on \(confirmedDate), but not introduced."
        } else {
            let introducedDate = formatter.string(from: introducedOn!)
            return "Confirmed \(confirmedDate), Introduced on \(introducedDate)"
        }
    }
}

extension ManagedIssuer : IssuerIntroductionRequestDelegate {
    func postData(for issuer: Issuer, from recipient: Recipient) -> [String : Any] {
        guard let nonce = self.nonce else {
            return [:]
        }
        return [
            "nonce": nonce
        ]
    }
}


protocol ManagedIssuerDelegate : class {
    func updated(managedIssuer: ManagedIssuer)
}
