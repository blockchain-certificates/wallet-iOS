//
//  WebAuthIssuerTests.swift
//  certificatesUITests
//
//  Created by Chris Downie on 8/30/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

class WebAuthIssuerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        //
        // In these set of tests, we're launching the app
        //   * With a known passphrase, to avoid onboarding
        //
        let app = XCUIApplication()
        app.launchArguments = [ "--reset-data", "--use-passphrase", testPassphrase]
        app.launch()
    }
    
    func testAddingWebAuthIssuer() {
        let app = XCUIApplication()
        XCTAssertEqual(app.collectionViews.cells.count, 0)
        XCTAssertFalse(app.collectionViews.cells["Web Auth Issuer"].exists)
        
        app.collectionViews.buttons["ADD ISSUER"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let issuerUrlTextField = elementsQuery.textFields["Issuer URL"]
        issuerUrlTextField.tap()
        issuerUrlTextField.typeText("http://localhost:1234/issuer/web-auth")
        
        let oneTimeCodeTextField = elementsQuery.textFields["One-Time Code"]
        oneTimeCodeTextField.tap()
        oneTimeCodeTextField.tap()
        oneTimeCodeTextField.typeText("12345")
        app.navigationBars["Add Issuer"].buttons["Save"].tap()
        
        XCTAssert(app.navigationBars["Log In To Issuer"].exists)
        XCTAssert(app.staticTexts["Web Authentication Challenge"].waitForExistence(timeout: 5))
        
        app.links["Yes"].tap()
        
        XCTAssert(app.navigationBars["Issuers"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.collectionViews.cells.count, 1)
        XCTAssert(app.collectionViews.cells["Web Auth Issuer"].exists)
    }
    
    func testAddingWebAuthIssuerFromLink() {
        let app = XCUIApplication()
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        
        // Launch Safari, go to our test page, and click our universal link.
        safari.launch()
        safari.otherElements["URL"].tap()
        safari.textFields["URL"].typeText("http://localhost:1234/links/web-auth-issuer\n")
        let webpage = safari.staticTexts["Link for Web Auth Issuer"]
        XCTAssert(webpage.waitForExistence(timeout: 5))
        safari.links["Click Here"].tap()
        
        // At this point, we should be back in our app.
        XCTAssert(app.navigationBars["Log In To Issuer"].exists)
        XCTAssert(app.staticTexts["Web Authentication Challenge"].waitForExistence(timeout: 5))
        
        app.links["Yes"].tap()
        
        XCTAssert(app.navigationBars["Issuers"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.collectionViews.cells.count, 1)
        XCTAssert(app.collectionViews.cells["Web Auth Issuer"].exists)
    }
    
    func testDoubleWebAuth() {
        //
        // We're going to try to get into a weird state on this one. While we're in the middle of the
        // web-auth prompt, we're going to kick over to Safari and click a deep link.
        //
        let app = XCUIApplication()
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        
        // Launch Safari, go to our test page, and click our universal link.
        safari.launch()
        safari.otherElements["URL"].tap()
        safari.textFields["URL"].typeText("http://localhost:1234/links/web-auth-issuer\n")
        let webpage = safari.staticTexts["Link for Web Auth Issuer"]
        XCTAssert(webpage.waitForExistence(timeout: 5))
        safari.links["Click Here"].tap()
        
        // At this point, we should be back in our app.
        XCTAssert(app.navigationBars["Log In To Issuer"].exists)
        XCTAssert(app.staticTexts["Web Authentication Challenge"].waitForExistence(timeout: 5))
        
        // Just kidding. Let's go back to Safari and click that link again.
        safari.activate()
        safari.links["Click Here"].tap()
        
        // At this point, we should be back in our app.
        XCTAssert(app.navigationBars["Log In To Issuer"].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["Web Authentication Challenge"].waitForExistence(timeout: 5))
        
        app.links["Yes"].tap()
        
        XCTAssert(app.navigationBars["Issuers"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.collectionViews.cells.count, 1)
        XCTAssert(app.collectionViews.cells["Web Auth Issuer"].exists)
    }
    
    func testFailingWebAuth() {
        let app = XCUIApplication()
        XCTAssertEqual(app.collectionViews.cells.count, 0)
        XCTAssertFalse(app.collectionViews.cells["Web Auth Issuer"].exists)
        
        app.collectionViews.buttons["ADD ISSUER"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let issuerUrlTextField = elementsQuery.textFields["Issuer URL"]
        issuerUrlTextField.tap()
        issuerUrlTextField.typeText("http://localhost:1234/issuer/web-auth")
        
        let oneTimeCodeTextField = elementsQuery.textFields["One-Time Code"]
        oneTimeCodeTextField.tap()
        oneTimeCodeTextField.tap()
        oneTimeCodeTextField.typeText("12345")
        app.navigationBars["Add Issuer"].buttons["Save"].tap()
        
        XCTAssert(app.navigationBars["Log In To Issuer"].exists)
        XCTAssert(app.staticTexts["Web Authentication Challenge"].waitForExistence(timeout: 5))
        
        app.links["No"].tap()
        
        let alert = app.alerts["Add Issuer Failed"]
        XCTAssert(alert.waitForExistence(timeout: 5))
        
        alert.buttons["OK"].tap()
        
        XCTAssert(app.navigationBars["Add Issuer"].exists)
    }
}
