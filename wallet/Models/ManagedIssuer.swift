//
//  ManagedIssuer.swift
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
    case genericError(error: Error?, data: Data?)
    case invalidState(reason: String)
    case untrustworthyIssuer(reason: String)
    case abortedIdentificationStep
    case abortedIntroductionStep
    case issuerInvalid(reason: InvalidIssuerReason, scope: InvalidIssuerScope)
    case serverErrorDuringIdentification(code: Int, message: String)
    case serverErrorDuringIntroduction(code: Int, message: String)
    case authenticationFailure
}

class ManagedIssuer : NSObject, NSCoding, Codable {
    private let tag = String(describing: ManagedIssuer.self)
    
    var delegate : ManagedIssuerDelegate?
    var issuerDescription : String?
    
    private(set) var issuerConfirmedOn: Date?
    private(set) var isIssuerConfirmed = false
    
    private(set) var introducedWithAddress : BlockchainAddress?
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
    
    init(issuer: Issuer?,
                 hostedIssuer: Issuer?,
                 isIssuerConfirmed: Bool = false,
                 issuerConfirmedOn: Date? = nil,
                 introducedWithAddress: BlockchainAddress? = nil) {
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
        introducedWithAddress = try container.decodeIfPresent(BlockchainAddress.self, forKey: .introducedWithAddress)
        let introducedOnString = try container.decodeIfPresent(String.self, forKey: .introducedOn)
        introducedOn = introducedOnString?.toDate()
        
        // TODO: Fix this
        hostedIssuer = try IssuerParser.decodeIfPresent(from: container, forKey: .hostedIssuer)
        sourceIssuer = try IssuerParser.decodeIfPresent(from: container, forKey: .sourceIssuer)
        
        nonce = nil
        delegate = nil
        issuerDescription = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(issuerConfirmedOn?.toString(), forKey: .issuerConfirmedOn)
        try container.encodeIfPresent(introducedWithAddress, forKey: .introducedWithAddress)
        try container.encodeIfPresent(introducedOn?.toString(), forKey: .introducedOn)
        
        try IssuerParser.encodeIfPresent(hostedIssuer, to: &container, forKey: .hostedIssuer)
        try IssuerParser.encodeIfPresent(sourceIssuer, to: &container, forKey: .sourceIssuer)
    }
    
    // MARK: NSCoding
    required convenience init?(coder decoder: NSCoder) {
        var address : BlockchainAddress? = nil
        if let addressString = decoder.decodeObject(forKey: CodingKeys.introducedWithAddress.rawValue) as? String {
            address = BlockchainAddress(string: addressString)
        }
        var issuer : Issuer?
        var hostedIssuer : Issuer?
        let isConfirmed = decoder.decodeBool(forKey: CodingKeys.isIssuerConfirmed.rawValue)
        let confirmedDate = decoder.decodeObject(forKey: CodingKeys.issuerConfirmedOn.rawValue) as? Date
        
        if let issuerDictionary = decoder.decodeObject(forKey: CodingKeys.sourceIssuer.rawValue) as? [String: Any] {
            issuer = IssuerParser.parse(dictionary: issuerDictionary, logger: Logger.main.toLoggerProtocol())
        }
        if let hostedIssuerDictionary = decoder.decodeObject(forKey: CodingKeys.hostedIssuer.rawValue) as? [String: Any] {
            hostedIssuer = IssuerParser.parse(dictionary: hostedIssuerDictionary, logger: Logger.main.toLoggerProtocol())
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
    
    // MARK: Add (Identify and introduce)
    func add(from url: URL, nonce: String, completion: @escaping (ManagedIssuerError?) -> Void) {
        let tag = self.tag
        
        Logger.main.tag(tag).debug("add called with url: \(url)")
        identify(from: url) { [weak self] identificationError in
//        identify { [weak self] identificationError in
            guard identificationError == nil else {
                DispatchQueue.main.async {
                    Logger.main.tag(tag).error("identification error in add")
                    completion(identificationError)
                }
                return
            }
            
            self?.introduce(nonce: nonce, completion: { introductionError in
                DispatchQueue.main.async {
                    if (introductionError != nil) {
                        Logger.main.tag(tag).error("introduction error in add")
                    }
                    completion(introductionError)
                }
            })
        }
    }
    
    // MARK: Identification step
    func manage(issuer: Issuer, completion: @escaping (ManagedIssuerError?) -> Void) {
        Logger.main.tag(tag).info("manage call")
        guard self.issuer == nil else {
            Logger.main.tag(tag).error("invalid state: this manager is called for -- it already has an issuer it's managing.")
            completion(.invalidState(reason: "This manager is called for -- it already has an issuer it's managing."))
            return
        }
        
        self.sourceIssuer = issuer
        
        identify(completion: completion)
    }
    
    func identify(completion: @escaping (ManagedIssuerError?) -> Void) {
        Logger.main.tag(tag).info("identify_1 call")
        guard let issuer = self.issuer else {
            Logger.main.tag(tag).error("invalid state: Can't call \(#function) when Issuer isn't set. Use manage(issuer:completion:) instead.")
            completion(.invalidState(reason: "Can't call \(#function) when Issuer isn't set. Use manage(issuer:completion:) instead."))
            return
        }
        
        identify(from: issuer.id, completion: completion)
    }
    
    func identify(from url: URL, completion: @escaping (ManagedIssuerError?) -> Void) {
        let tag = self.tag
        Logger.main.tag(tag).debug("identify_2 \(url)")
        
        Logger.main.tag(tag).debug("calling IssuerIdentificationRequest")
        let identityRequest = IssuerIdentificationRequest(id: url, logger: Logger.main.toLoggerProtocol()) { [weak self] (possibleIssuer, error) in
            var returnError : ManagedIssuerError? = nil
            Logger.main.tag(tag).debug("IssuerIdentificationRequest response for url: \(url)")
            
            self?.inProgressRequest = nil
            self?.issuerConfirmedOn = Date()
            self?.hostedIssuer = possibleIssuer
            self?.isIssuerConfirmed = (error == nil)
            
            if possibleIssuer != nil && self?.issuer?.id != possibleIssuer?.id {
                Logger.main.tag(tag).error("untrustworthyIssuer: the issuer we're managing has a different ID in the issuer's JSON. This means the issuer's hosting JSON has changed ownership.")
                returnError = .untrustworthyIssuer(reason:"The issuer we're managing has a different ID in the issuer's JSON. This means the issuer's hosting JSON has changed ownership.")
            }
            
            if let error = error {
                self?.isIssuerConfirmed = false
                
                switch (error) {
                case .aborted:
                    Logger.main.tag(tag).error("IssuerIdentificationRequest response: aborted. abortedIdentificationStep")
                    returnError = .abortedIdentificationStep
                case .missingJSONData:
                    Logger.main.tag(tag).error("IssuerIdentificationRequest response: missingJSONData. issuerInvalid. reason: missing, scope: json")
                    returnError = .issuerInvalid(reason: .missing, scope: .json)
                case .jsonSerializationFailure:
                    Logger.main.tag(tag).error("IssuerIdentificationRequest response: jsonSerializationFailure. issuerInvalid. reason: missing, scope: json")
                    returnError = .issuerInvalid(reason: .invalid, scope: .json)
                case .issuerMissing(let property):
                    Logger.main.tag(tag).error("IssuerIdentificationRequest response: issuerMissing. issuerInvalid. reason: missing, scope: \(property)")
                    returnError = .issuerInvalid(reason: .missing, scope: .property(named: property))
                case .issuerInvalid(let property):
                    Logger.main.tag(tag).error("IssuerIdentificationRequest response: issuerInvalid. issuerInvalid. reason: invalid, scope: \(property)")
                    returnError = .issuerInvalid(reason: .invalid, scope: .property(named: property))
                case .httpFailure(let status, let response):
                    Logger.main.tag(tag).error("IssuerIdentificationRequest response: httpFailure. serverErrorDuringIdentification. code: \(status), message: \(response.description)")
                    returnError = .serverErrorDuringIdentification(code: status, message: response.description)
                    
                case .unknownResponse:
                    Logger.main.tag(tag).error("IssuerIdentificationRequest response: unknownResponse")
                    fallthrough
                default:
                    Logger.main.tag(tag).error("IssuerIdentificationRequest response: unknownResponse. genericError")
                    returnError = .genericError(error: nil, data: nil)
                }
            }
            
            if returnError != nil {
                Logger.main.tag(tag).error("issuer identification at \(url) error.")
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
    
    /*
    // This is currently unused. Moving to a function here for potential future use.
    func identifyErrorDisplayString(identifyError: ManagedIssuerError?) -> String {
        switch(identifyError!) {
        case .invalidState(let reason):
            // This is a developer error, so write it to the log so we can see it later.
            Logger.main.fatal("Invalid ManagedIssuer state: \(reason)")
            return NSLocalizedString("The app is in an invalid state. Please quit the app & relaunch. Then try again.", comment: "Invalid state error message when adding an issuer.")
        
        case .untrustworthyIssuer:
            return NSLocalizedString("This issuer appears to have been tampered with. Please contact the issuer.", comment: "Error message when the issuer's data doesn't match the URL it's hosted at.")
        
        case .abortedIntroductionStep:
            return NSLocalizedString("The request was aborted. Please try again.", comment: "Error message when an identification request is aborted")
        
        case .serverErrorDuringIdentification(let code, let message):
            Logger.main.error("Error during issuer identification: \(code) \(message)")
            return NSLocalizedString("The server encountered an error. Please try again.", comment: "Error message when an identification request sees a server error")
        
        case .serverErrorDuringIntroduction(let code, let message):
            Logger.main.error("Error during issuer introduction: \(code) \(message)")
            return NSLocalizedString("The server encountered an error. Please try again.", comment: "Error message when an identification request sees a server error")
        
        case .issuerInvalid(_, scope: .json):
            return NSLocalizedString("We couldn't understand this Issuer's response. Please contact the Issuer.", comment: "Error message displayed when we see missing or invalid JSON in the response.")
        
        case .issuerInvalid(reason: .missing, scope: .property(let named)):
            return String.init(format: NSLocalizedString("Issuer responded, but didn't include the \"%@\" property", comment: "Format string for an issuer response with a missing property. Variable is the property name that's missing."), named)
        
        case .issuerInvalid(reason: .invalid, scope: .property(let named)):
            return String.init(format: NSLocalizedString("Issuer responded, but it contained an invalid property named \"%@\"", comment: "Format string for an issuer response with an invalid property. Variable is the property name that's invalid."), named)
            
        case .authenticationFailure:
            Logger.main.error("Failed to authenticate the user to the issuer. Either because of a bad nonce or a failed web auth.")
            return NSLocalizedString("We couldn't authenticate you to the issuer. Double-check your one-time code and try again.", comment: "This error is presented when the user uses a bad nonce")
        
        case .genericError(let error, let data):
            var message : String?
            if data != nil {
                message = String(data: data!, encoding: .utf8)
            }
            Logger.main.error("Generic error during add issuer: \(error?.localizedDescription ?? "none"), data: \(message ?? "none")")
            return NSLocalizedString("Adding this issuer failed. Please try again", comment: "Generic error when adding an issuer.")
        
        default:
            return NSLocalizedString("Something went wrong adding this issuer. Try again later.", comment: "Generic error for failure to add an issuer")
        }
    }
    */
    
    // MARK: Introduction step
    func introduce(nonce: String, completion: @escaping (ManagedIssuerError?) -> Void) {
        let tag = self.tag
        
        Logger.main.tag(tag).debug("introduce call with nonce: \(nonce)")
        guard let issuer = issuer else {
            Logger.main.tag(tag).error("can't introduce until we have a valid Issuer.")
            completion(.invalidState(reason: "Can't introduce until we have a valid Issuer."))
            return
        }
        
        let recipient = Recipient(givenName: "",
                                  familyName: "",
                                  identity: "",
                                  identityType: "email",
                                  isHashed: false,
                                  publicAddress: Keychain.shared.nextPublicAddress(),
                                  revocationAddress: nil)
        
        self.nonce = nonce
        Logger.main.tag(tag).info("calling IssuerIntroductionRequest")
        let introductionRequest = IssuerIntroductionRequest(introduce: recipient, to: issuer, loggingTo: Logger.main.toLoggerProtocol()) { [weak self] (error) in
            Logger.main.tag(tag).info("IssuerIntroductionRequest response")
            self?.introducedOn = Date()
            self?.inProgressRequest = nil
            
            var reportError : ManagedIssuerError? = nil
            
            if let error = error {
                self?.introducedWithAddress = nil
                
                switch (error) {
                case .aborted:
                    Logger.main.tag(tag).error("IssuerIntroductionRequest response: aborted. abortedIntroductionStep")
                    reportError = .abortedIntroductionStep
                case .issuerMissingIntroductionURL:
                    Logger.main.tag(tag).error("IssuerIntroductionRequest response: issuerMissingIntroductionURL. issuerInvalid. reason: missing, scope: introductionURL")
                    reportError = .issuerInvalid(reason: .missing, scope: .property(named: "introductionURL"))
                case .cannotSerializePostData:
                    Logger.main.tag(tag).error("IssuerIntroductionRequest response: cannotSerializePostData. issuerInvalid. reason: invalid, scope: json")
                    reportError = .issuerInvalid(reason: .invalid, scope: .json)
                case .errorResponseFromServer(let response, let data):
                    var dataString : String? = nil
                    if data != nil {
                        dataString = String(data: data!, encoding: .utf8)
                    }
                    Logger.main.tag(tag).error("IssuerIntroductionRequest response: errorResponseFromServer. serverErrorDuringIntroduction. code: \(response.statusCode), message: \(response.description) \(dataString ?? "")")
                    reportError = .serverErrorDuringIntroduction(code: response.statusCode, message: "\(response.description)\n\n\(dataString ?? "") ")
                case .webAuthenticationFailed:
                    Logger.main.tag(tag).error("IssuerIntroductionRequest response: webAuthenticationFailed.")
                    fallthrough
                case .authenticationFailed:
                    Logger.main.tag(tag).error("IssuerIntroductionRequest response: authenticationFailed. authenticationFailure")
                    reportError = .authenticationFailure
                case .genericErrorFromServer(let error, let data):
                    reportError = .genericError(error: error, data: data)
                    if let e = error, let d = data {
                        Logger.main.tag(tag).error("IssuerIntroductionRequest response: genericErrorFromServer. genericError error: \(e), data: \(d)")
                    } else {
                        Logger.main.tag(tag).error("IssuerIntroductionRequest response: genericErrorFromServer.")
                    }
                default:
                    Logger.main.tag(tag).error("IssuerIntroductionRequest response: error. genericError")
                    reportError = .genericError(error: nil, data: nil)
                }
            } else {
                Logger.main.tag(tag).debug("recipient: \(recipient)")
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
        Logger.main.tag(tag).info("abort_requests")
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
        Logger.main.tag(tag).info("present_web_view")
        try delegate?.presentWebView(at: url, with: navigationDelegate)
    }
    
    func dismissWebView() {
        Logger.main.tag(tag).info("dismiss_web_view")
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
