//
//  DeepLinkOnFreshInstall.swift
//  certificatesUITests
//
//  Created by Chris Downie on 9/29/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

class DeepLinkOnFreshInstall: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = [ "--reset-data" ]
        app.launch()
    }
    
    func testAddIssuerLink() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let app = XCUIApplication()
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        
        // Launch Safari, go to our test page, and click our universal link.
        safari.launch()
        safari.otherElements["URL"].tap()
        safari.textFields["URL"].typeText("http://localhost:1234/links/universal-links\n")
        let webpage = safari.staticTexts["Add Issuer Links"]
        XCTAssert(webpage.waitForExistence(timeout: 5))
        safari.links["Add Accepting Issuer"].tap()
        
        XCTAssert(app.buttons["NEW ACCOUNT"].waitForExistence(timeout: 5))
    }
    
}
