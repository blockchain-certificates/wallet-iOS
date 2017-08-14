//
//  ManagedIssuerManagerTests.swift
//  certificatesTests
//
//  Created by Chris Downie on 8/14/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest
import Blockcerts

class ManagedIssuerManagerTests: XCTestCase {
//    func testLoadingNSCodingIssuers() {
//        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("issuers-1")
//        let testBundle = Bundle(for: type(of: self))
//        guard let fileURL = testBundle.url(forResource: "issuers-nscoding", withExtension: nil) else {
//            XCTFail("Failed to load file for this test.")
//            return
//        }
//        let manager = ManagedIssuerManager(readFrom: tempURL, writeTo: tempURL, convertFrom: fileURL)
//
//        let managedIssuers = manager.load()
//        XCTAssert(managedIssuers.count > 0)
//    }
    
    func testLoadingCodableIssuers() {
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: "issuers-codable", withExtension: "json") else {
            XCTFail("Failed to load file for this test.")
            return
        }
        let manager = ManagedIssuerManager(readFrom: fileUrl, writeTo: fileUrl)
        
        let managedIssuers = manager.load()
        XCTAssert(managedIssuers.count > 0)
    }
    
    func testSavingCodableIssuers() {
        let issuerV2 = IssuerV2(name: "Name",
                                email: "em@ail.com",
                                image: Data(),
                                id: URL(string: "http://blockcerts.org/issuer/id")!,
                                url: URL(string: "http://blockcerts.org/")!,
                                revocationURL: URL(string: "https://blockcerts.org/revocation")!,
                                publicKeys: [
                                    KeyRotation(on: Date(timeIntervalSince1970: 0), key: "EXAMPLE_KEY")
                                ],
                                introductionMethod: .basic(introductionURL: URL(string: "https://blockcerts.org/intro")!),
                                analyticsURL: nil)
        let issuers = [
            ManagedIssuer(issuer: issuerV2, hostedIssuer: issuerV2, isIssuerConfirmed: true, issuerConfirmedOn: Date(timeIntervalSince1970: 0), introducedWithAddress: "ADDRESS_INTRODUCED")
        ]
        // TODO: Let's add some managed Issuers to that list, shall we?
        
        let writeURL = FileManager.default.temporaryDirectory.appendingPathComponent("issuers-2")
        let writeManager = ManagedIssuerManager(readFrom: writeURL, writeTo: writeURL)
        let success = writeManager.save(issuers)
        
        XCTAssert(success)
        
        let alternateWriteURL = FileManager.default.temporaryDirectory.appendingPathComponent("issuers-3")
        let alternateManager = ManagedIssuerManager(readFrom: writeURL, writeTo: alternateWriteURL)
        let readIssuers = alternateManager.load()
        
        XCTAssertEqual(readIssuers.count, issuers.count)
    }
}
