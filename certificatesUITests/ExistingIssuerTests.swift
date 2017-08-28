//
//  ExistingIssuerTests.swift
//  certificatesUITests
//
//  Created by Chris Downie on 8/18/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

//let testPassphrase = "view virtual ice oven upon material humor vague vessel jacket aim clarify moral gesture canvas wing shoot average charge section issue inmate waste large"

class ExistingIssuerTests: XCTestCase {
        
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
        let app = XCUIApplication()
        // We start with just one issuer
        XCTAssertEqual(app.collectionViews.cells.count, 1)
        XCTAssertFalse(app.collectionViews.cells["Greendale College"].exists)
        
        // We add a second
        app.navigationBars["Issuers"].buttons["AddIcon"].tap()

        let elementsQuery = app.scrollViews.otherElements
        let issuerUrlTextField = elementsQuery.textFields["Issuer URL"]
        issuerUrlTextField.tap()
        issuerUrlTextField.typeText("http://localhost:1234/accepting_issuer.json")

        let oneTimeCodeTextField = elementsQuery.textFields["One-Time Code"]
        oneTimeCodeTextField.tap()
        oneTimeCodeTextField.tap()
        oneTimeCodeTextField.typeText("12345")
        app.navigationBars["Add Issuer"].buttons["Save"].tap()
        
        // We now have 2 issuers, and one of them is Greendale
        XCTAssertEqual(app.collectionViews.cells.count, 2)
        XCTAssert(app.collectionViews.cells["Greendale College"].exists)
    }
    
}
