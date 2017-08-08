//
//  File.swift
//  wallet
//
//  Created by Chris Downie on 11/1/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import Foundation
import Blockcerts
import WebKit

enum InvalidIssuerReason {
    case missing, invalid
}

enum InvalidIssuerScope {
    case json, property(named: String)
}

enum ManagedIssuerError {
    case genericError
    case invalidState(reason: String)
    case untrustworthyIssuer(reason: String)
    case abortedIdentificationStep
    case abortedIntroductionStep
    case issuerInvalid(reason: InvalidIssuerReason, scope: InvalidIssuerScope)
    case serverError(code: Int)

}

class ManagedIssuer : NSObject, NSCoding, Decodable {
    var delegate : ManagedIssuerDelegate?
    var issuerDescription : String?
    
    
    private(set) var issuerConfirmedOn: Date?
    private(set) var isIssuerConfirmed = false
    
    private(set) var introducedWithAddress : String?
    private(set) var introducedOn: Date?
    
    private var inProgressRequest : CommonRequest?
    
    // `issuer` is the publicly visible issuer instance. It's always up to date with what's on the server
    // `hostedIssuer` is the issuer data reported at the issuer's id
    // `sourceIssuer` is the issuer data
    public var issuer : Issuer? {
        if let sourceIssuer = sourceIssuer {
            if let hostedIssuer = hostedIssuer, hostedIssuer.id == sourceIssuer.id {
                return hostedIssuer
            } else {
                return sourceIssuer
            }
        } else {
            return hostedIssuer
        }
    }
    
    private var hostedIssuer : Issuer?
    private var sourceIssuer : Issuer?
    
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
        self.sourceIssuer = issuer
        self.hostedIssuer = hostedIssuer
        self.isIssuerConfirmed = isIssuerConfirmed
        self.issuerConfirmedOn = issuerConfirmedOn
        self.introducedWithAddress = introducedWithAddress
        
        super.init()
    }
    
    // MARK: Codable
    private enum CodingKeys : String, CodingKey {
        // These all match their case names, but their raw values are used in NSCoding
        case sourceIssuer = "issuer"
        case hostedIssuer = "hostedIssuer"
        case isIssuerConfirmed = "isIssuerConfirmed"
        case issuerConfirmedOn = "issuerConfirmedOn"
        case introducedWithAddress = "introducedWithAddress"
        case introducedOn = "introducedOn"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let issuerConfirmedOnString = try container.decodeIfPresent(String.self, forKey: .issuerConfirmedOn)
        issuerConfirmedOn = issuerConfirmedOnString?.toDate()
        isIssuerConfirmed = (issuerConfirmedOn != nil)
        introducedWithAddress = try container.decodeIfPresent(String.self, forKey: .introducedWithAddress)
        let introducedOnString = try container.decodeIfPresent(String.self, forKey: .introducedOn)
        introducedOn = introducedOnString?.toDate()
        
        // TODO: Fix this
        hostedIssuer = try IssuerParser.decode(from: container, forKey: .hostedIssuer)
        sourceIssuer = try IssuerParser.decode(from: container, forKey: .sourceIssuer)
        
        nonce = nil
        delegate = nil
        issuerDescription = nil
        
    }
    
    // MARK: NSCoding
    required convenience init?(coder decoder: NSCoder) {
        let address = decoder.decodeObject(forKey: CodingKeys.introducedWithAddress.rawValue) as? String
        var issuer : Issuer?
        var hostedIssuer : Issuer?
        let isConfirmed = decoder.decodeBool(forKey: CodingKeys.isIssuerConfirmed.rawValue)
        let confirmedDate = decoder.decodeObject(forKey: CodingKeys.issuerConfirmedOn.rawValue) as? Date
        
        if let issuerDictionary = decoder.decodeObject(forKey: CodingKeys.sourceIssuer.rawValue) as? [String: Any] {
            issuer = IssuerParser.parse(dictionary: issuerDictionary)
        }
        if let hostedIssuerDictionary = decoder.decodeObject(forKey: CodingKeys.hostedIssuer.rawValue) as? [String: Any] {
            hostedIssuer = IssuerParser.parse(dictionary: hostedIssuerDictionary)
        }
        
        if issuer == nil && hostedIssuer == nil {
            return nil
        }
        
        self.init(issuer: issuer,
                  hostedIssuer: hostedIssuer,
                  isIssuerConfirmed: isConfirmed,
                  issuerConfirmedOn: confirmedDate,
                  introducedWithAddress: address)
    }
    
    func encode(with coder: NSCoder) {
        if let issuer = self.issuer {
            coder.encode(issuer.toDictionary(), forKey: CodingKeys.sourceIssuer.rawValue)
        }
        if let hostedIssuer = self.hostedIssuer {
            coder.encode(hostedIssuer.toDictionary(), forKey: CodingKeys.hostedIssuer.rawValue)
        }
        coder.encode(isIssuerConfirmed, forKey: CodingKeys.isIssuerConfirmed.rawValue)
        coder.encode(issuerConfirmedOn, forKey: CodingKeys.issuerConfirmedOn.rawValue)
        coder.encode(introducedWithAddress, forKey: CodingKeys.introducedWithAddress.rawValue)
    }
    
    
    // MARK: Identification step
    func manage(issuer: Issuer, completion: @escaping (ManagedIssuerError?) -> Void) {
        guard self.issuer == nil else {
            completion(.invalidState(reason: "This manager is called for -- it already has an issuer it's managing."))
            return
        }
        
        self.sourceIssuer = issuer
        
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
            
            if possibleIssuer != nil && self?.issuer?.id != possibleIssuer?.id {
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
    
    func introduce(recipient: Recipient, with nonce: String, completion: @escaping (ManagedIssuerError?) -> Void) {
        guard let issuer = issuer else {
            completion(.invalidState(reason: "Can't introduce until we have a valid Issuer."))
            return
        }
        
        self.nonce = nonce
        let introductionRequest = IssuerIntroductionRequest(introduce: recipient, to: issuer) { [weak self] (error) in
            self?.introducedOn = Date()
            self?.inProgressRequest = nil
            
            var reportError : ManagedIssuerError? = nil
            
            if let error = error {
                self?.introducedWithAddress = nil
                
                switch (error) {
                case .aborted:
                    reportError = .abortedIntroductionStep
                case .issuerMissingIntroductionURL:
                    reportError = .issuerInvalid(reason: .missing, scope: .property(named: "introductionURL"))
                case .cannotSerializePostData:
                    reportError = .issuerInvalid(reason: .invalid, scope: .json)
                case .errorResponseFromServer(let response):
                    reportError = .serverError(code: response.statusCode)
                case .genericErrorFromServer:
                    fallthrough
                default:
                    reportError = .genericError
                }
            } else {
                self?.introducedWithAddress = recipient.publicAddress
            }
            
            // Call the completion handler & delegate
            completion(reportError)
            
            if self != nil {
                self!.delegate?.updated(managedIssuer: self!)
            }
        }
        introductionRequest.delegate = self
        inProgressRequest?.abort()
        introductionRequest.start()
        inProgressRequest = introductionRequest
    }
    
    func abortRequests() {
        inProgressRequest?.abort()
        dismissWebView()
    }
}

extension ManagedIssuer : IssuerIntroductionRequestDelegate {
    func introductionData(for issuer: Issuer, from recipient: Recipient) -> [String : Any] {
        guard let nonce = self.nonce else {
            return [:]
        }
        return [
            "nonce": nonce
        ]
    }
    
    func presentWebView(at url:URL, with navigationDelegate:WKNavigationDelegate) throws {
        try delegate?.presentWebView(at: url, with: navigationDelegate)
    }
    
    func dismissWebView() {
        delegate?.dismissWebView()
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



protocol ManagedIssuerDelegate : class {
    func updated(managedIssuer: ManagedIssuer)
    
    func presentWebView(at url:URL, with navigationDelegate:WKNavigationDelegate) throws
    func dismissWebView()

}

extension ManagedIssuerDelegate {
    func updated(managedIssuer: ManagedIssuer) {}
    func presentWebView(at url:URL, with navigationDelegate:WKNavigationDelegate) throws {
        throw IssuerIntroductionRequestError.introductionMethodNotSupported
    }
    func dismissWebView() {}
}
