//
//  ExistingCertificateTests.swift
//  certificatesUITests
//
//  Created by Chris Downie on 8/18/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

//
// These tests are all of mainnet-issued certificates that exposed a bug. They're here to prevent regressions.
// Unfortunately, since they're mainnet, it also means we can't change them. We can't mock out any issuer data or
// bitcoin network transactions. So, these tests are likely to occasionally give false negatives due to network conditions.
//
// You've been warned.
//
class MainnetCertificateTests: XCTestCase {
    let certificateDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("existing-certificate-tests")
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        //
        // In these set of tests, we're launching the app
        //   * With a known passphrase, to avoid onboarding
        //   * With an existing issuer (Downie Test Org)
        //
        
        if !FileManager.default.fileExists(atPath: certificateDirectory.path) {
            try! FileManager.default.createDirectory(at: certificateDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        let testBundle = Bundle(for: type(of: self))
        let certURL = testBundle.url(forResource: "mainnet", withExtension: "json")!
        do {
            try FileManager.default.copyItem(at: certURL, to: certificateDirectory.appendingPathComponent("certificate.json"))
        } catch {
            print("Failed to copy demo certificate because \(error)")
        }
        
        let app = XCUIApplication()
        app.launchArguments = [ "--reset-data", "--use-passphrase", testPassphrase, "--use-certificates-in-directory", certificateDirectory.path]
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
        
        let files = try? FileManager.default.contentsOfDirectory(atPath: certificateDirectory.path)
        for filename in files ?? [] {
            do {
                try FileManager.default.removeItem(atPath: certificateDirectory.appendingPathComponent(filename).path)
            } catch {
                print("Failed to remove item \(error)")
            }
        }
    }
    
    func testDataLoading() {
        let app = XCUIApplication()
        XCTAssert(app.collectionViews.cells["Main Net Prod Test"].exists)
    }
    
    func testVerificationOfCertificate() {
        let app = XCUIApplication()
        app.collectionViews.cells["Main Net Prod Test"].tap()
        app.tables/*@START_MENU_TOKEN@*/.staticTexts["Cert Alignment 0718"]/*[[".cells.staticTexts[\"Cert Alignment 0718\"]",".staticTexts[\"Cert Alignment 0718\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.toolbars.buttons["Verify"].tap()
        
        // Now that we've tapped "verify", let's wait until we see the success alert
        XCTAssert(app.alerts["Success"].waitForExistence(timeout: 5))
    }
}


class MainnetCertificate20180829Tests: XCTestCase {
    let certificateDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("existing-certificate-tests")
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        //
        // In these set of tests, we're launching the app
        //   * With a known passphrase, to avoid onboarding
        //   * With an existing issuer (Downie Test Org)
        //
        
        if !FileManager.default.fileExists(atPath: certificateDirectory.path) {
            try! FileManager.default.createDirectory(at: certificateDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        let testBundle = Bundle(for: type(of: self))
        let certURL = testBundle.url(forResource: "mainnet-2017-08-29", withExtension: "json")!
        do {
            try FileManager.default.copyItem(at: certURL, to: certificateDirectory.appendingPathComponent("certificate.json"))
        } catch {
            print("Failed to copy demo certificate because \(error)")
        }
        
        let app = XCUIApplication()
        app.launchArguments = [ "--reset-data", "--use-passphrase", testPassphrase, "--use-certificates-in-directory", certificateDirectory.path]
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
        
        let files = try? FileManager.default.contentsOfDirectory(atPath: certificateDirectory.path)
        for filename in files ?? [] {
            do {
                try FileManager.default.removeItem(atPath: certificateDirectory.appendingPathComponent(filename).path)
            } catch {
                print("Failed to remove item \(error)")
            }
        }
    }
    
    func testDataLoading() {
        let app = XCUIApplication()
        XCTAssert(app.collectionViews.cells["Main Net Prod Test"].exists)
    }
    
    func testVerificationOfCertificate() {
        let app = XCUIApplication()
        app.collectionViews.cells["Main Net Prod Test"].tap()
        app.tables.staticTexts["Daily Test Cert - 081617"].tap()
        app.toolbars.buttons["Verify"].tap()
        
        // Now that we've tapped "verify", let's wait until we see the success alert
        XCTAssert(app.alerts["Success"].waitForExistence(timeout: 5))
    }
}



