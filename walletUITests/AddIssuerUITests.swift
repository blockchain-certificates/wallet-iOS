//
//  AddIssuerUITests.swift
//  wallet
//
//  Created by Chris Downie on 1/6/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

// Disabling this test, since it's broken with the new flow & landing screen.
//class AddIssuerUITests: XCTestCase {
//        
//    override func setUp() {
//        super.setUp()
//        
//        // In UI tests it is usually best to stop immediately when a failure occurs.
//        continueAfterFailure = false
//        
//        let app = XCUIApplication()
//        app.launchArguments = [ "--reset-data" ]
//        app.launch()
//    }
//    
//    func testRestorePassphraseFlow() {
//        
//    }
//    
//    func testAddGameOfThronesIssuer() {
//        
//        let app = XCUIApplication()
//        
//        XCTAssertFalse(app.collectionViews.cells["Game of thrones issuer on testnet"].exists, "Should start without Game of Thrones issuer existing. Otherwise this test is useless.")
//
//        app.navigationBars[""].buttons["Add"].tap()
//        app.sheets.buttons["Add Issuer"].tap()
//        
//        let elementsQuery = app.scrollViews.otherElements
//        let issuerUrlTextField = elementsQuery.textFields["Issuer URL"]
//        issuerUrlTextField.tap()
//        issuerUrlTextField.typeText("http://www.blockcerts.org/mockissuer/issuer/got-issuer.json")
//        
//        let oneTimeCode = elementsQuery.textFields["One-Time Code"]
//        oneTimeCode.tap()
//        oneTimeCode.typeText("12345")
//        
//        XCUIApplication().navigationBars["Add Issuer"].buttons["Save"].tap()
//        
//        XCTAssert(app.navigationBars["Issuers"].exists, "Should be back on the Issuers screen.")
//        XCTAssert(app.collectionViews.cells["Game of thrones issuer on testnet"].exists, "Now, we should have a Game of Thrones issuer in the top screen.")
//    }
//    
//}
