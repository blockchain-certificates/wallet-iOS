//
//  AddIssuerUITests.swift
//  wallet
//
//  Created by Chris Downie on 1/6/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import XCTest

class AddIssuerUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        app.launchArguments = [ "--reset-data" ]
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAddGameOfThronesIssuer() {
        let app = XCUIApplication()
        
        XCTAssertFalse(app.collectionViews.cells["Game of thrones issuer on testnet"].exists, "Should start without Game of Thrones issuer existing. Otherwise this test is useless.")

        app.navigationBars["Issuers"].buttons["Add"].tap()
        app.sheets.buttons["Add Issuer"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let issuerUrlTextField = elementsQuery.textFields["Issuer URL"]
        issuerUrlTextField.tap()
        issuerUrlTextField.typeText("http://www.blockcerts.org/mockissuer/issuer/got-issuer.json")
        
        let oneTimeCode = elementsQuery.textFields["One-Time Code"]
        oneTimeCode.tap()
        oneTimeCode.typeText("12345")
        
        XCUIApplication().navigationBars["Add Issuer"].buttons["Save"].tap()
        print(app.collectionViews.cells.count)
        
        XCTAssert(app.navigationBars["Issuers"].exists, "Should be back on the Issuers screen.")
        XCTAssert(app.collectionViews.cells["Game of thrones issuer on testnet"].exists, "Now, we should have a Game of Thrones issuer in the top screen.")

    }
    
}
