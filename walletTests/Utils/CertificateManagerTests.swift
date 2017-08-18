//
//  CertificateManagerTests.swift
//  certificatesTests
//
//  Created by Chris Downie on 8/18/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest
import Blockcerts

class CertificateManagerSingleCertificateTests: XCTestCase {
    let readDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("single-certificate-test-input")
    
    override func setUp() {
        if !FileManager.default.fileExists(atPath: readDirectory.path) {
            try! FileManager.default.createDirectory(at: readDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        let testBundle = Bundle(for: type(of: self))
        let certURL = testBundle.url(forResource: "mainnet", withExtension: "json")!
        do {
        try FileManager.default.copyItem(at: certURL, to: readDirectory.appendingPathComponent("certificate.json"))
        } catch {
            print("uh oh \(error)")
        }
        
    }
    
    override func tearDown() {
        let files = try? FileManager.default.contentsOfDirectory(atPath: readDirectory.path)
        for filename in files ?? [] {
            do {
                try FileManager.default.removeItem(atPath: readDirectory.appendingPathComponent(filename).path)
            } catch {
                print("Failed to remove item \(error)")
            }
        }
    }
    
    func testLoadingSingleCertificate() {
        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent("test-output")
        let manager = CertificateManager(readFrom: readDirectory, writeTo: tempPath)
        let certificates = manager.loadCertificates()
        
        XCTAssertEqual(certificates.count, 1)
        XCTAssertEqual(certificates.first!.issuer.name, "Main Net Prod Test")
    }
    
    func testSavingSingleCertificate() {
        let certURL = Bundle(for: type(of: self)).url(forResource: "mainnet", withExtension: "json")!
        let file = FileManager.default.contents(atPath: certURL.path)!
        
        let certificate = try! CertificateParser.parse(data: file)
        
        let outputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("test-output")
        let manager = CertificateManager(readFrom: outputDirectory, writeTo: outputDirectory)
        
        manager.save(certificate: certificate)
        
        let fileList = try! FileManager.default.contentsOfDirectory(atPath: outputDirectory.path)
        
        XCTAssertEqual(fileList.count, 1)
        XCTAssertEqual(fileList.first, certificate.filename)
    }
}
