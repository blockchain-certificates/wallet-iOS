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
        
        let title = app.staticTexts["Web Authentication Challenge"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: title, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        app.links["Yes"].tap()
        
        let nav = app.navigationBars["Issuers"]
        expectation(for: exists, evaluatedWith: nav, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
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
        
        let title = app.staticTexts["Web Authentication Challenge"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: title, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        app.links["No"].tap()
        
        let alert = app.alerts["Add Issuer Failed"]
        expectation(for: exists, evaluatedWith: alert, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        alert.buttons["OK"].tap()
        
        XCTAssert(app.navigationBars["Add Issuer"].exists)
    }
}
