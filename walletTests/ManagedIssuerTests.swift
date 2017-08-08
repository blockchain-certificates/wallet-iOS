//
//  ManagedIssuerTests.swift
//  certificatesTests
//
//  Created by Chris Downie on 8/8/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

class ManagedIssuerTests: XCTestCase {
    func testManagedIssuerCodable() {
        // Attempt decode
        let issuerFile = "managed-issuer"
        let testBundle = Bundle(for: type(of: self))
        guard let fileUrl = testBundle.url(forResource: issuerFile, withExtension: "json") ,
            let file = try? Data(contentsOf: fileUrl) else {
                return
        }
        
        let decoder = JSONDecoder()
        do {
            let managed = try decoder.decode(ManagedIssuer.self, from: file)
            XCTAssertEqual(managed.issuer?.id, URL(string: "https://www.blockcerts.org/samples/2.0/issuer-testnet.json")!)
            XCTAssertEqual(managed.issuer?.name, "University of Learning")
            XCTAssertEqual(managed.issuer?.email, "contact@issuer.org")
            XCTAssertEqual(managed.issuer?.publicKeys.first?.key, "ecdsa-koblitz-pubkey:msBCHdwaQ7N2ypBYupkp6uNxtr9Pg76imj")
        } catch {
            XCTFail("Something went wrong \(error)")
        }
        
        // Attempt encode
//        let issuer = IssuerV2Alpha(name: "Name",
//                                   email: "Email@address.com",
//                                   image: Data(),
//                                   id: URL(string: "https://issuer.com/blockcerts")!,
//                                   url: URL(string: "https://issuer.com")!,
//                                   revocationURL: URL(string: "https://issuer.com/revoke")!,
//                                   publicKeys: [KeyRotation(on: Date(timeIntervalSince1970: 0), key: "ISSUER_KEY")],
//                                   introductionMethod: .basic(introductionURL: URL(string: "https://issuer.com/intro")!),
//                                   analyticsURL: nil)
//        let encoder = JSONEncoder()
//        do {
//            let data = try encoder.encode(issuer)
//            let result = try decoder.decode(IssuerV2Alpha.self, from: data)
//            XCTAssertEqual(issuer, result)
//        } catch {
//            XCTFail("Encoding (or decoding after the fact) failed: \(error)")
//        }
    }
}
