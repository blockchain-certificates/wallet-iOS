//
//  ExistingCertificateTests.swift
//  certificatesUITests
//
//  Created by Chris Downie on 8/18/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

class ExistingCertificateTests: XCTestCase {
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
        try! FileManager.default.copyItem(at: certURL, to: certificateDirectory.appendingPathComponent("certificate.json"))

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
