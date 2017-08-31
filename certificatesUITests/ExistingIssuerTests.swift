//
//  ExistingIssuerTests.swift
//  certificatesUITests
//
//  Created by Chris Downie on 8/18/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

//let testPassphrase = "view virtual ice oven upon material humor vague vessel jacket aim clarify moral gesture canvas wing shoot average charge section issue inmate waste large"

class ExistingDownieIssuerTests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        //
        // In these set of tests, we're launching the app
        //   * With a known passphrase, to avoid onboarding
        //   * With an existing issuer (Downie Test Org)
        //
        let issuerData = Bundle(for: type(of: self)).url(forResource: "Downie-Issuer", withExtension: "json")!
        let app = XCUIApplication()
        app.launchArguments = [ "--reset-data", "--use-passphrase", testPassphrase, "--use-issuer-data", issuerData.path]
        app.launch()
    }
    
    func testIssuerDataLoadedCorrectly() {
        let app = XCUIApplication()
        let issuerTile = app.collectionViews.cells["Downie Test Org"]
        
        XCTAssertEqual(app.collectionViews.cells.count, 1)
        XCTAssert(issuerTile.exists)
        
        issuerTile.tap()
        let issuerNavigationBar = app.navigationBars["Downie Test Org"]
        
        XCTAssert(issuerNavigationBar.exists)
    }
    
    func testAddingSecondIssuer() {
        print("\n\n\nTestAddingSecondIssuer\n\n\n")
        defer {
            print("\n\n\nTestAddingSecondIssuer Complete\n\n\n")
        }
        let app = XCUIApplication()
        // We start with just one issuer
        XCTAssertEqual(app.collectionViews.cells.count, 1)
        XCTAssertFalse(app.collectionViews.cells["Greendale College"].exists)
        
        // We add a second
        app.navigationBars["Issuers"].buttons["AddIcon"].tap()

        let elementsQuery = app.scrollViews.otherElements
        let issuerUrlTextField = elementsQuery.textFields["Issuer URL"]
        issuerUrlTextField.tap()
        issuerUrlTextField.typeText("http://localhost:1234/issuer/accepting")

        let oneTimeCodeTextField = elementsQuery.textFields["One-Time Code"]
        oneTimeCodeTextField.tap()
        oneTimeCodeTextField.tap()
        oneTimeCodeTextField.typeText("12345")
        app.navigationBars["Add Issuer"].buttons["Save"].tap()
        
        // We now have 2 issuers, and one of them is Greendale
        XCTAssertEqual(app.collectionViews.cells.count, 2)
        XCTAssert(app.collectionViews.cells["Greendale College"].exists)
    }
    
    func testAddingMismatchedCertificate() {
        let app = XCUIApplication()
        app.collectionViews.cells["Downie Test Org"].tap()
        app.navigationBars["Downie Test Org"].buttons["AddIcon"].tap()
        app.sheets.buttons["Import Certificate from URL"].tap()
        
        let alertsQuery = app.alerts
        alertsQuery.collectionViews.textFields["URL"].typeText("http://localhost:1234/issuer/accepting/certificates/student.json")
        alertsQuery.buttons["Import"].tap()
        
        let certificateNavBar = app.navigationBars["You're a student"]
        XCTAssert(certificateNavBar.waitForExistence(timeout: 5))
        
        // Back button shouldn't be to DownieTestOrg
        let backButton = certificateNavBar.buttons["Greendale College"]
        XCTAssert(backButton.exists)
        backButton.tap()
        XCTAssert(app.navigationBars["Greendale College"].exists)
    }
}

class ExistingAcceptingIssuerTests : XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        //
        // In these set of tests, we're launching the app
        //   * With a known passphrase, to avoid onboarding
        //   * With an existing issuer (Downie Test Org)
        //
        let issuerData = Bundle(for: type(of: self)).url(forResource: "Accepting-Issuer", withExtension: "json")!
        let app = XCUIApplication()
        app.launchArguments = [ "--reset-data", "--use-passphrase", testPassphrase, "--use-issuer-data", issuerData.path]
        app.launch()
    }
    
    func testIssuerDataLoadedCorrectly() {
        let app = XCUIApplication()
        let issuerTile = app.collectionViews.cells["Greendale College"]
        
        XCTAssertEqual(app.collectionViews.cells.count, 1)
        XCTAssert(issuerTile.exists)
        
        issuerTile.tap()
        let issuerNavigationBar = app.navigationBars["Greendale College"]
        
        XCTAssert(issuerNavigationBar.exists)
    }
    
    func testAddingCertificateToIssuer() {
        let app = XCUIApplication()
        app.collectionViews.cells["Greendale College"].tap()
        XCTAssertFalse(app.tables.staticTexts["Welcome to Greendale!"].exists)
        
        app.navigationBars["Greendale College"].buttons["AddIcon"].tap()
        app.sheets.buttons["Import Certificate from URL"].tap()
        
        let alertsQuery = app.alerts
        alertsQuery.collectionViews.textFields["URL"].typeText("http://localhost:1234/issuer/accepting/certificates/student.json")
        alertsQuery.buttons["Import"].tap()
        
        XCTAssert(app.navigationBars["You're a student"].waitForExistence(timeout: 5))
        app.navigationBars["You're a student"].buttons["Greendale College"].tap()

        XCTAssert(app.navigationBars["Greendale College"].exists)
        XCTAssert(app.tables.staticTexts["Welcome to Greendale!"].exists)
//
//
//        let app = XCUIApplication()
//        app.collectionViews.cells["Greendale College"].tap()
//        app.tables/*@START_MENU_TOKEN@*/.staticTexts["Welcome to Greendale!"]/*[[".cells.staticTexts[\"Welcome to Greendale!\"]",".staticTexts[\"Welcome to Greendale!\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
    }
}
